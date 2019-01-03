#!/bin/bash
#############################################################
# Author : Suman Adhikari                                  ##
# Company : Nepasoft Solution                              ##
# Description : This script is developed for manual        ##
#               Standby database configuration for         ##
#               standard edition databases. It will        ##
#               stop the recovery and start database in    ##
#               readonly mode and again start recover when ##
#               specified arguments are passed.            ##
#############################################################


#############################################################
# Set the appropriate environmental variables               #
#############################################################

##
## Set Oracle Specific Environmental env's
##
export ORACLE_HOSTNAME=`hostname`
export ORACLE_HOME=/u02/app/oracle/product/11.2.0.4/db_1
export ORACLE_SID="orcldr"
DBMODE=""

##
## Current user executing the script
##
RESTORE_USER=`whoami`

##
## Env for locating full path of the script being executed
##
CURSCRIPT=`readlink -f $0`


##
## Variables for generating logfiles 
##
RECOVERY_LOG_DIR="/archive/syncstandby/diag"
RECOVERY_ARCH_DIR="/archive/orcldr/"
RSYNC_LOG_FILE=${RECOVERY_LOG_DIR}/alertRECOVER_${ORACLE_SID}.log
RSYNC_START_TIME=""
RSYNC_END_TIME=""

##
## For Warning and Text manupulation
##
bold=$(tput bold)
reset=$(tput sgr0)
bell=$(tput bel)
underline=$(tput smul)


#############################################################
# Functions to handle exceptions and erros                  #
#############################################################

###
### Handling error while running script
###
### $1 : Error Code
### $2 : Error message in detail
###

ReportError(){
	if [ "${3}" != "" ]
		then
			echo "" >> ${RSYNC_LOG_FILE}
			echo "########################################################" >> ${RSYNC_LOG_FILE}
			echo -e "Error during Running Script :\n$CURSCRIPT" >> ${RSYNC_LOG_FILE}
			echo -e "$1: $2" >> ${RSYNC_LOG_FILE}
			echo "########################################################" >> ${RSYNC_LOG_FILE}
			echo "" >> ${RSYNC_LOG_FILE}
			exit 1;
	else
			echo "########################################################"
			echo "Error during Running Script : $CURSCRIPT"
			echo -e "$1: $2"
			echo "########################################################"
			exit 1;
	fi
}

###
### Dispalying information based on input of user 
### OR
### Status of script while running.
###

ReportInfo(){
	if [ "${2}" != "" ]
		then
			echo "" >> ${RSYNC_LOG_FILE}
			echo "########################################################" >> ${RSYNC_LOG_FILE}
			echo -e "Information by the script :\n$CURSCRIPT\n" >> ${RSYNC_LOG_FILE}
			echo -e "INFO : $1 " >> ${RSYNC_LOG_FILE}
			echo "########################################################" >> ${RSYNC_LOG_FILE}
			echo "" >> ${RSYNC_LOG_FILE}
	else 
			echo "########################################################"
			echo "Information by the script : $CURSCRIPT"
			echo -e "INFO : $1 "
			echo "########################################################"
	fi
}


###
### FUNCTION TO CHECK FUNDAMENTAL VARIABLES
###

CheckVars(){
	if [ "${1}" = "" ]
	then
		ReportError "RERR-001" "${bell}${bold}${underline}ORACLE_HOME${reset} Env variable not Set. Aborting...." "Y"
		
	elif [ ! -d ${1} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or ORACLE_HOME Env invalid. Aborting...." "Y"
	
	elif [ ! -x ${1}/bin/sqlplus ]
	then
		ReportError  "RERR-003" "Executable \"${bell}${bold}${underline}${1}/bin/sqlplus${reset}\" not found; Aborting..." "Y"
       
	elif [ "${2}" = "" ]
        then
                ReportError  "RERR-004" "${bell}${bold}${underline}ORACLE_SID${reset} Env variable not Set. Aborting..." "Y"

	elif [ "${3}" != "oracle" ]
        then
                ReportError  "RERR-004" "User "${bell}${bold}${underline}${2}${reset}" not valid for running script; Aborting..." "Y"
	
        elif [ "${4}" = "" ]
        then
                ReportError "RERR-001" "${bell}${bold}${underline}RECOVERY_ARCH_DIR${reset} Env variable not Set. Aborting...." "Y"

        elif [ ! -d ${4} ]
        then
                ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${4}${reset}\" not found or RECOVERY_ARCH_DIR Env invalid. Aborting...." "Y"

	else
		return 0;
	fi
}


checkSidValid(){
	param1=("${!1}")
	check=${2}  
	statusSID=0
	for i in ${param1[@]}
		do
			if [ ${i} == $2 ];
				then
				statusSID=1
				break
			esle
                echo $i; 
			fi 
        done
    return $statusSID;
}

###
### Get Oracle SID env 
###
FunGetOracleSID(){
myarr=($(ps -ef | grep ora_smon| grep -v grep | awk -F' ' '{print $NF}' | cut -c 10-))
checkSidValid myarr[@] ${ORACLE_SID}
if [ $? -eq 0 ]
	then
		ReportError  "\nRERR-005" "ORACLE_SID : ${bell}${bold}${underline}${ORACLE_SID}${reset} Env is invalid, no instance is running. Aborting..." "Y"
fi

ReportInfo "\nChecking for validness for ORACLE_SID: ${bell}${bold}${underline}${ORACLE_SID}${reset} passed....." "Y"
}

###
### Get the Database open mode...
###
FunGetDBmode(){
DBMODE=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select open_mode from v\$database;
END
)
}

###
### Shutdown the instance
###
FunShutdownDB(){
case ${2} in
    I|i )
	ReportInfo "${3}" "Y"
        $1/bin/sqlplus -s /nolog <<EOF >> ${RSYNC_LOG_FILE}
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        shutdown immediate;
EOF
        ;;

        A|a )
	ReportInfo "${3}" "Y"
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        shutdown abort;
EOF
        ;;

    * )
        ReportInfo "${3}" "Y"
    ;;
esac

}

###
### Start the database
###
FunStartDB(){
case ${2} in
    n|N )
	ReportInfo "${3}" "Y"
        $1/bin/sqlplus -s /nolog <<EOF >> ${RSYNC_LOG_FILE} 
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup nomount;
EOF
        ;;

        m|M )
	ReportInfo "${3}" "Y"
        $1/bin/sqlplus -s /nolog <<EOF >> ${RSYNC_LOG_FILE}
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup mount;
EOF
        ;;

	o|O )
	ReportInfo "${3}" "Y"
        $1/bin/sqlplus -s /nolog <<EOF >> ${RSYNC_LOG_FILE}
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup;
EOF
        ;;

        r|R )
	ReportInfo "${3}" "Y" 
        $1/bin/sqlplus /nolog <<EOF >> ${RSYNC_LOG_FILE}
        set pagesize 0 verify off echo off;
        connect / as sysdba
        startup mount;
	alter database open read only;
	select name, open_mode, database_role from v\$database;
EOF
        ;;


    * )
        ReportInfo "Startup of instance skipped......."
    ;;
esac

}

###
### Function to enable disable scheduling
###
FunHandleSchedule(){
    if [ ${1} = 'D' ]
        then
			ReportInfo "Disabling Schedule job for recovery ........." "Y"
			# Backing up crontab entries before any changes take palce
			crontab -l > ${RECOVERY_LOG_DIR}/temp/crontab.tmp
			# delete the corntab entries for specific ORACLE_SID
			crontab -l | grep -v "startrecovery ${ORACLE_SID}" | grep -v grep | crontab
			
	elif [ ${1} = 'E' ]
		then
			ReportInfo "Enabling Schedule job for recovery ........." "Y"
			#cat crontab.tmp | grep "startrecovery ${ORACLE_SID}" > crontab_${ORACLE_SID}.tmp
			crontab -l | awk '{print} END {system("cat crontab.tmp | grep \"startrecovery ${ORACLE_SID}\"") }' | corntab
			#crontab -l | awk '{print} END {print "*/15 * * * * /archive/standbyscripts/recover.sh"}' | crontab
	
	else
			ReportError "NEP-001" ${bell}${bold}${underline}"Scheduling status cannot be determined."${reset}" Aborting...."
	fi
}


###
### Function to apply archived logs
###
FunApplyArchivelogs(){
ReportInfo "${2}" "Y"
${1}/bin/sqlplus / as sysdba >> /dev/null <<EOF >> ${RSYNC_LOG_FILE}
col "APPLY DATE and TIME" format a30
col "Finished DATE and TIME" format a30
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "APPLY DATE and TIME" FROM DUAL;
select name, open_mode, database_role from v\$database;
select 'Last Archive Sequence Applied : '||max(SEQUENCE#) "Archive Applied" from v\$log_history where thread#=1;
recover standby database
AUTO
select 'Last Archive Sequence Applied : '||max(SEQUENCE#) "Archive Applied" from v\$log_history where thread#=1;
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Finished DATE and TIME" FROM DUAL;
exit;
EOF
}

###
### Function to apply the archives
###
FunStartMediaRecovery(){
FunGetDBmode ${ORACLE_HOME}

	if [ "${DBMODE}" = "MOUNTED" ]
	then
		FunShutdownDB ${ORACLE_HOME} "no" "Database instance ${ORACLE_SID} found on mounted mode, no action required....."
        else
		FunShutdownDB ${ORACLE_HOME} "i" "Shutting down Database instance ${ORACLE_SID} ....."
		FunStartDB ${ORACLE_HOME} "m" "Opening Database instance ${ORACLE_SID} in mounted mode ...."
	fi
	FunApplyArchivelogs ${ORACLE_HOME} "Applying Archive logs to Database instance ${ORACLE_SID} ....."
}


###
### If ORACLE_SID is passed during running the script 
### Give the priority to the passed variable
###
if [ "${2}" = "" ]
	then
	echo ""
else
	export ORACLE_SID=${2}
fi

###
### If RECOVERY_ARCH_DIR is passed during running the script
### Give the priority to the passed variable
###
if [ "${3}" = "" ]
        then
        echo ""
else
        export RECOVERY_ARCH_DIR=${3}
fi


###
### Function to handle the Standby Database conf
###


CheckVars ${ORACLE_HOME} ${ORACLE_SID} ${RESTORE_USER} ${RECOVERY_ARCH_DIR}
ReportInfo "\nChecking fundamental variables passed....." "Y"
FunGetOracleSID
#FunStartMediaRecovery

case "$1" in
    'openreadonly')
        #####################################################
        # Stop the Recovery for standby database            #
        # Open Database in Read only mode                   #
        #####################################################
	FunHandleSchedule "D"
        FunShutdownDB ${ORACLE_HOME} "i" "Shutting down Database instance ${ORACLE_SID} to open in read only mode ....."
	FunStartDB ${ORACLE_HOME} "R" "Opening database instance ${ORACLE_SID} in read only mode ....."
	;;
    'startrecovery')
        #####################################################
        # Shutdown the database in normalmode               #
        # Start the recovery Process                        #
        #####################################################
        FunStartMediaRecovery
	;;
    'checkstatus')
        #####################################################
        # Check the applied archived form both nodes        #
        #####################################################
        /archive/standbyscripts/checkstatus.sh
        ;;
    'applyarchive')
        #####################################################
        # Apply the transfered archived logs                #
        #####################################################
        /archive/standbyscripts/recover.sh
        ;;
    * )
        #####################################################
        # Shutdown the database in normalmode               #
        # Start the recovery Process                        #
        #####################################################
        FunStartMediaRecovery
        ;;

esac
