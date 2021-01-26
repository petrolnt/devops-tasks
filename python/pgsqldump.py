#!/usr/bin/python

import os
from datetime import datetime, time, timedelta, date
import syslog

DB_HOST = 'foundation-production.cdgpyfyn8vyp.eu-central-1.rds.amazonaws.com'
DB_USER = 'awsroot'
DB_NAME = 'foundation'
BACKUP_PATH = '/root/dump_db_foundation/'
DAYS_OVER = 10
S3_FOLDER = '/root/dump_db_foundation/petrol-foundation-backups/'

passFileCmd = 'export PGPASSFILE=/root/.pgpass'
os.popen(passFileCmd)

date = datetime.now()
strDate = date.strftime('%d_%m_%Y')
oldDate = date - timedelta(days = DAYS_OVER)
strOldDate = oldDate.strftime('%d_%m_%Y')

currentBackupName = BACKUP_PATH +  DB_NAME + "_"  + strDate + ".zip"
dumpcmd = "/usr/bin/pg_dump -h " + DB_HOST  + " -U " + DB_USER + " " + DB_NAME + " -f foundation.sql;zip -P x5%Ew9 " + currentBackupName + " foundation.sql;rm -f foundation.sql"
retval = os.popen(dumpcmd).read()

mvcmd = "mv " + currentBackupName + " " + S3_FOLDER
retval = os.popen(mvcmd).read()

oldFile = S3_FOLDER + DB_NAME + '_' + strOldDate + '.zip'
if(os.path.exists(oldFile)):
    try:
	os.remove(oldFile)
    except OSError, e:
	syslog.syslog(syslog.LOG_ERR, e)
