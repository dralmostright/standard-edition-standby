#!/bin/bash
#############################################################
# Author : Suman Adhikari                                  ##
# Company : Nepasoft Solution                              ##
# Description : This script is developed for manual        ##
#               Standby database configuration for         ##
#               standard edition databases. It will        ##
#               ship the archives one way to standby on    ##
#		incremental basis.			   ##
#############################################################

RSYNC_LOG_DIR="/archive/syncstandby/diag"
RSYNC_SRC_DIR="/archive/orcl/"
RSYNC_DEST_DIR="/archive/orcldr/"
RSYNC_REMOTEHOST="oraggbktp"
RSYNC_USER=`whoami`
RSYNC_LOG_FILE=${RSYNC_LOG_DIR}/alertRSYNC.log
RSYNC_START_TIME=""
RSYNC_END_TIME=""
##
## Env for locating full path of the script being executed
##
#CURSCRIPT=`realpath $0`
CURSCRIPT=`readlink -f $0`

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
			echo "########################################################" >> ${RSYNC_LOG_FILE}
			echo "Error during Running Script : $CURSCRIPT" >> ${RSYNC_LOG_FILE}
			echo -e "$1: $2" >> ${RSYNC_LOG_FILE}
			echo "########################################################" >> ${RSYNC_LOG_FILE}
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
		ReportError "RERR-001" "${bell}${bold}${underline}RSYNC_LOG_DIR${reset} Environmental variable not Set. Aborting...." "Y"
		
	elif [ ! -d ${1} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or RSYNC_LOG_DIR Env invalid. Aborting...." "Y"
	
	elif [ "${2}" = "" ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}RSYNC_SRC_DIR${reset}\" not found or RSYNC_SRC_DIR Env invalid. Aborting...." "Y"
	
	elif [ ! -d ${2} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${2}${reset}\" not found or RSYNC_SRC_DIR Env invalid. Aborting...." "Y"

	elif [ "${3}" = "" ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}RSYNC_DEST_DIR${reset}\" not found or RSYNC_DEST_DIR Env invalid. Aborting...." "Y"
	
	elif [ "${4}" = "" ]
        then
                ReportError  "RERR-003" "Remote host env "${bell}${bold}${underline}RSYNC_REMOTEHOST${reset}" not valid; Aborting..." "Y"
				
	elif [ "${5}" != "oracle" ]
        then
                ReportError  "RERR-004" "User "${bell}${bold}${underline}${2}${reset}" not valid for running script; Aborting..." "Y"
				
	else
		return 0;
	fi
}


FunResyncArch(){
	#local totalSize
	CheckVars ${RSYNC_LOG_DIR} ${RSYNC_SRC_DIR} ${RSYNC_DEST_DIR} ${RSYNC_REMOTEHOST} ${RSYNC_USER}
	ReportInfo "Variables status verification passed..." "Y"
	ReportInfo "\nSource Dir : ${RSYNC_SRC_DIR}\nSource Host : `hostname`\nDestination Host : ${RSYNC_REMOTEHOST}\nDestination Dir : ${RSYNC_DEST_DIR}\nArchivelog Synchronization Start Time :\n`date +%d/%m/%Y\ %H:%M:%S`" "Y"
	RSYNC_START_TIME=`date +%s`
	rsync -e ssh -Pazv --stats ${RSYNC_SRC_DIR} oracle@${RSYNC_REMOTEHOST}:${RSYNC_DEST_DIR} >> ${RSYNC_LOG_FILE}
	RSYNC_END_TIME=`date +%s`
	ReportInfo "\nArchivelog Synchronization Finish Time :\n`date +%d/%m/%Y\ %H:%M:%S`" "Y"
	TOTAL_TIME=`expr ${RSYNC_END_TIME} - ${RSYNC_START_TIME}`
	#totalSize=`tail -21 ${RSYNC_LOG_FILE} | head -1 | awk '{ print $5 }' | sed 's/,//g'`
	TOTAL_TIME=`printf '%d Hour : %d Minutes : %d Seconds\n' $((${TOTAL_TIME}/3600)) $((${TOTAL_TIME}%3600/60)) $((${TOTAL_TIME}%60))`
	ReportInfo "\nArchivelog Synchronization Total Time :\n${TOTAL_TIME}" "Y" 
}

FunResyncArch
