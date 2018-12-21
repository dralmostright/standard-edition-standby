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
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export ORACLE_SID=""

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
export NS_STNADBY_BASE=/u01/app/oracle
DATE_AND_TIME=`date +%d_%m_%Y`
LOG_FILE_NAME=`dirname ${CURSCRIPT}`/Sessionrestore_${DATE_AND_TIME}.log


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
       echo "########################################################"
       echo "Error during Running Script : $CURSCRIPT"
       echo -e "$1: $2"
       echo "########################################################"
       exit 1;
}

###
### Dispalying information based on input of user 
### OR
### Status of script while running.
###

ReportInfo(){
       echo "########################################################"
       echo "Information by the script : $CURSCRIPT"
       echo -e "INFO : $1 "
       echo "########################################################"
}


###
### FUNCTION TO CHECK FUNDAMENTAL VARIABLES
###

CheckVars(){
	if [ "${1}" = "" ]
	then
		ReportError "RERR-001" "${bell}${bold}${underline}ORACLE_HOME${reset} Environmental variable not Set. Aborting...."
		
	elif [ ! -d ${1} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or ORACLE_HOME Env invalid. Aborting...."
	
	elif [ ! -x ${1}/bin/sqlplus ]
		then
			ReportError  "RERR-003" "Executable \"${bell}${bold}${underline}${1}/bin/sqlplus${reset}\" not found; Aborting..."
       
	elif [ "${2}" != "oracle" ]
        then
                ReportError  "RERR-004" "User "${bell}${bold}${underline}${2}${reset}" not valid for running script; Aborting..."
	else
		return 0;
	fi
}



##
## Function to check if any specific value exists in array
##

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
echo "--------> List of Oracle Database Instance running on box: ${bold}${underline}`hostname`${reset}"

for i in "${myarr[@]}"
	do :
	echo "-----------> Oracle Database Instance: "${bold}${underline}$i${reset} 
	done
}

myarr=($(ps -ef | grep ora_smon | awk -F' ' '{print $NF}' | cut -c 10-))
#myarr=($(ps -ef |grep smon | awk -F'_' '{print $3}'))
echo "--------> List of Oracle Database Instance running on box: ${bold}${underline}`hostname`${reset}"

for i in "${myarr[@]}"
	do :
	echo "-----------> Oracle Database Instance: "${bold}${underline}$i${reset} 
	done

if [[ "${ORA_INSTANCE}" = "" ]]
then
printf  'Enter the database instance for which Health Check should be Performed : '
read -r ORA_INSTANCE
export ORACLE_SID=`echo $ORA_INSTANCE`
fi

##
## Get the environment variables for the respective instance
## Get the ORACLE sid
export ORACLE_SID=`echo $ORA_INSTANCE`


##
## Get the date and time for name of the folders
##
export DATE_TIME=`date +%d_%m_%Y`
#export FILE_NAME=$destdir"/DBarchitecture_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".log"
export FILE_NAME=$destdir"/DBarchitecture_"$ORA_INSTANCE"_DBHC_"$DATE_TIME".html"




###
### Function to enable disable scheduling
###
FunHandleSchedule(){
    if [ ${1} = 'N' ]
        then
			ReportInfo "Disabling Schedule job for recovery ........."
			crontab -l | sed '\!/archive/standbyscripts/recover.sh!d' | crontab
			
	elif [ ${1} = 'E' ]
		then
			crontab -l | awk '{print} END {print "*/15 * * * * /archive/standbyscripts/recover.sh"}' | crontab
			ReportInfo "Enabling Schedule job for recovery ........."
	
	else
			ReportError "NEP-001" ${bell}${bold}${underline}"Scheduling status cannot be determined."${reset}" Aborting...."
	fi
}


###
### Function to open database on readonly mode
###
FunOpenDbReadOnly(){
$ORACLE_HOME/bin/sqlplus >> /dev/null <<EOF >> /archive/standbylogs/open_readonly.log 
sys / as sysdba
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Stop DATE and TIME" FROM DUAL;
select name, open_mode, database_role from v\$database;
SELECT MAX(RECID) "Max Applied Log sequence" FROM V\$LOG_HISTORY;
alter database open read only;
select name, open_mode, database_role from v\$database;
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Opened DATE and TIME" FROM DUAL;
exit;
EOF
}

###
### Function to retart recovery
###
FunRecoverDb(){
$ORACLE_HOME/bin/sqlplus >> /dev/null <<EOF >> /archive/standbylogs/start_recovery.log
sys / as sysdba
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Start DATE and TIME" FROM DUAL;
select name, open_mode, database_role from v\$database;
SELECT MAX(RECID) "Max Applied Log sequence" FROM V\$LOG_HISTORY;
shutdown immediate;
startup mount;
select name, open_mode, database_role from v\$database;
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Recover DATE and TIME" FROM DUAL;
exit;
EOF
}

###
### Function to check sync status
###
FunCheckSyncStatus(){

}


crontab -l | sed '\!/archive/standbyscripts/recover.sh!d' | crontab
$ORACLE_HOME/bin/sqlplus >> /dev/null <<EOF >> /archive/standbylogs/open_readonly.log 
sys / as sysdba
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Stop DATE and TIME" FROM DUAL;
select name, open_mode, database_role from v\$database;
SELECT MAX(RECID) "Max Applied Log sequence" FROM V\$LOG_HISTORY;
alter database open read only;
select name, open_mode, database_role from v\$database;
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Opened DATE and TIME" FROM DUAL;
exit;
EOF



$ORACLE_HOME/bin/sqlplus >> /dev/null <<EOF >> /archive/standbylogs/start_recovery.log
sys / as sysdba
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Start DATE and TIME" FROM DUAL;
select name, open_mode, database_role from v\$database;
SELECT MAX(RECID) "Max Applied Log sequence" FROM V\$LOG_HISTORY;
shutdown immediate;
startup mount;
select name, open_mode, database_role from v\$database;
SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Recover DATE and TIME" FROM DUAL;
exit;
EOF
crontab -l | awk '{print} END {print "*/15 * * * * /archive/standbyscripts/recover.sh"}' | crontab 


echo '####################################################'
echo '################ Checking Status ###################'
echo '####################################################'
STATUS=`$ORACLE_HOME/bin/sqlplus -silent / as sysdba <<EOF
@/archive/standbyscripts/sql_scripts/check_status.sql
exit;
EOF`

echo "$STATUS"
echo '####################################################'


export ORACLE_HOSTNAME=`hostname`
export ORACLE_UNQNAME=ptcbsdr
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export ORACLE_SID=ptcbs
echo "\n" >> /archive/standbylogs/recovery_log_file.log
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> /archive/standbylogs/recovery_log_file.log
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> /archive/standbylogs/recovery_log_file.log

$ORACLE_HOME/bin/sqlplus / as sysdba >> /dev/null <<EOF >> /archive/standbylogs/recovery_log_file.log

--#sys / as sysdba

SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "APPLY DATE and TIME" FROM DUAL;

select name, open_mode, database_role from v\$database;

select 'Archive Applied from node1: '||max(SEQUENCE#) "Archive Applied" from gv\$log_history where thread#=1
union all
select 'Archive Applied from node2: '||max(SEQUENCE#) "Archive Applied" from gv\$log_history where thread#=2;

recover standby database
AUTO

select 'Archive Applied from node1: '||max(SEQUENCE#) "Archive Applied" from gv\$log_history where thread#=1
union all
select 'Archive Applied from node2: '||max(SEQUENCE#) "Archive Applied"from gv\$log_history where thread#=2;

SELECT TO_CHAR (SYSDATE, 'MM-DD-YYYY HH24:MI:SS') "Finished DATE and TIME" FROM DUAL;

exit;
EOF
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" >> /archive/standbylogs/recovery_log_file.log
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" >> /archive/standbylogs/recovery_log_file.log
echo "\n" >> /archive/standbylogs/recovery_log_file.log



case "$1" in
    'openreadonly')
        #####################################################
        # Stop the Recovery for standby database            #
        # Open Database in Read only mode                   #
        #####################################################
        /archive/standbyscripts/open_readonly.sh
        ;;
    'startrecovery')
        #####################################################
        # Shutdown the database in normalmode               #
        # Start the recovery Process                        #
        #####################################################
        /archive/standbyscripts/start_recovery.sh
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
esac

