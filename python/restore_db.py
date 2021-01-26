
import os
from datetime import datetime, time, timedelta, date
import syslog, sys
from boto3.session import Session
import boto3
from zipfile import ZipFile

DB_NAME="mydb"
#DAYS_AGO=sys.argv[2]
#if(DAYS_AGO==""):
#    DAYS_AGO=0

passFileCmd = 'export PGPASSFILE=/home/someuser/.pgpass'
os.popen(passFileCmd)
BACKUP_PATH = '/path/to/dump/folder/'
date = datetime.now()
#oldDate = date - timedelta(days = 1)
strOldDate = date.strftime('%d_%m_%Y')

backupName = DB_NAME + "_"  + strOldDate + ".zip"

ACCESS_KEY = 'MY_ACCESS_KEY_ID'
SECRET_KEY = '%1q2w3e4r%'


s3 = boto3.client ('s3', aws_access_key_id=ACCESS_KEY, aws_secret_access_key=SECRET_KEY)

s3.download_file('s3_bucket_name',backupName,backupName)

with ZipFile(backupName) as zf:
    zf.extractall(pwd='archive_passord')

#restore_cmd = "pg_restore -v --no-owner -h 127.0.0.1 -d db_name -c db_name.dump"
restore_cmd = "psql -h 127.0.0.1 -d db_name < db_name.dump"
retval = os.popen(restore_cmd).read()

if(os.path.exists(backupName)):
    try:
        os.remove(backupName)
    except OSError as e:
        syslog.syslog(syslog.LOG_ERR, e)

if(os.path.exists("db_name.dump")):
    try:
        os.remove("db_name.dump")
    except OSError as e:
        syslog.syslog(syslog.LOG_ERR, e)

