MySQL-Replication-Check
=======================

## Description ##
Generic MySQL Replication Check.  
Compare master and slave position, examines MySQL replication gap.  
Alert in case of IO/SQL error and whether replication is delayed too much. Designed as Nagios check.  

Usage:
```
./generic_replication_check.pl --master 0.0.0.0 --slave 1.1.1.1
```

Grant on master and slave:
```
GRANT REPLICATION CLIENT ON *.* TO 'nagview'@'ip_addr' IDENTIFIED BY PASSWORD '*****';
```
