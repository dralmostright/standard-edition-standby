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
