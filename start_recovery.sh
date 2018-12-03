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
