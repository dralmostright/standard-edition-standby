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
