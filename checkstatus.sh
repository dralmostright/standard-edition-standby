echo '####################################################'
echo '################ Checking Status ###################'
echo '####################################################'
STATUS=`$ORACLE_HOME/bin/sqlplus -silent / as sysdba <<EOF
@/archive/standbyscripts/sql_scripts/check_status.sql
exit;
EOF`

echo "$STATUS"
echo '####################################################'
