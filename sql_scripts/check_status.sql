set lines 40
select 'Archive Applied from node1: '||max(SEQUENCE#) "Archive Applied" from v$log_history where thread#=1;

