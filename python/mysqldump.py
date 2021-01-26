#!/usr/bin/python

import os
from datetime import datetime, time, timedelta, date
import syslog

DB_HOST = 'localhost'
DB_USER = 'username'
DB_USER_PASSWORD = 'myPass'
DB_NAME = 'otrs'
BACKUP_PATH = '/backups/'
DAYS_OVER = 10

date = datetime.now()
strDate = date.strftime('%d_%m_%Y')
oldDate = date - timedelta(days = DAYS_OVER)
strOldDate = oldDate.strftime('%d_%m_%Y')

dumpcmd = "mysqldump -u " + DB_USER + " -p" + DB_USER_PASSWORD + " " + DB_NAME + " | gzip >> " + BACKUP_PATH +  DB_NAME + "_"  + strDate + ".gz"
retval = os.popen(dumpcmd).read()

oldFile = BACKUP_PATH + DB_NAME + '_' + strOldDate + '.gz'
if(os.path.exists(oldFile)):
    try:
	os.remove(oldFile)
    except OSError, e:
	syslog.syslog(syslog.LOG_ERR, e)
