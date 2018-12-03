# Scripts for creating Standby for Oracle DB in standard Edition

## Some info:
Author: Suman Adhikari

## Description:
This projects lists the scripts for how to create a duplicate(clone) database of production DB in standard edition which supports the following features of (physical)standby in Enterprise Edition. 
  ++   Keep the clone database in synchronized state with primary by applying change records(archivelogs) from primary. 
  ++   Open the database in read only mode for reporting purpose after first stopping the apply process. 

#### Reference
Oracle Support : Alternative for standby database in standard edition (Doc ID 333749.1)
