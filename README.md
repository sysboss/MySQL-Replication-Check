MySQL-Replication-Check
=======================

## Description ##
The most common task when managing a replication process is to ensure that replication is taking place and that there have been no errors between the slave and the master.  
  
Generic MySQL Replication check.  
Compare master and slave position, examines MySQL replication gap.  
Alert in case of IO/SQL error and whether replication is delayed too much.  
  
Designed as Nagios check.  

Usage:
```
./generic_replication_check.pl --master 0.0.0.0 --slave 1.1.1.1
```

Grant on master and slave:
```
GRANT REPLICATION CLIENT ON *.* TO 'nagview'@'ip_addr' IDENTIFIED BY PASSWORD '*****';
```
