# -*- coding: utf-8 -*-

import os, errno
from datetime import datetime,date,time,timedelta
import shutil
import os.path
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

srcPath = "/backups/gal81/"
dstPath = "/u01/backups/gal81/"

archSrcPath = "/backups/gal81/arch/"
archDstPath = "/u01/backups/gal81/arch/"

date = datetime.now()
strDate = date.strftime("%Y-%m-%d")
timeOfBackup = "02-10"
message = "<html><h3>Дублирование резервных копий с Галлактики на oes4 " + strDate + " </h3>"
#если 4 число то копируем файл в папку arch и переносим в arch на vgok-fs-001
if(date.day == 4):
    timeOfBackup = "18-00"
    nameOfCurrentFile = "gal81_" + strDate + "_" + timeOfBackup + ".tar.gz"
    srcFilePath = srcPath + nameOfCurrentFile
    if(os.path.exists(srcFilePath)):
	message += "Найден файл на vgok-fs-001 для копирования в архив " + srcFilePath + "<br/>"
	try:
	    shutil.copy(srcFilePath, archDstPath)
	    mbSize = (os.path.getsize(os.path.join(archDstPath, nameOfCurrentFile)))//1024//1024
	    message += "Скопирован файл {0} в папку {1}. Обьем файла: {2}Мб<br/>".format(nameOfCurrentFile,archDstPath, mbSize)
	    shutil.move(srcFilePath, archSrcPath)
	    mbSize = (os.path.getsize(os.path.join(archSrcPath, nameOfCurrentFile)))//1024//1024
	    message += "Перемещен файл {0} в папку {1}. Обьем файла: {2} Мб<br/>".format(nameOfCurrentFile,archSrcPath, mbSize)
	except IOError, e:
	    message += "Ошибка копирования файла % s" % s + "<br/>"
    else:
	message += "Файл " + srcFilePath + " для копирования в архив не найден" + "<br/>"

#во все остальные дни копируем файл в u02 и удаляем файл старее 92 дней	
else:
    oldDate = date - timedelta(days = 92)
    oldFileName = "gal81_" + oldDate.strftime("%Y-%m-%d") + "_" + timeOfBackup + ".tar.gz"
    nameOfCurrentFile = "gal81_" + strDate + "_" + timeOfBackup + ".tar.gz"
    srcFilePath = srcPath + nameOfCurrentFile
    
    if (os.path.exists(srcFilePath)):
	message += "Файл для копирования найден: " + srcFilePath + "<br/>"
	try:
	    shutil.copy(srcFilePath, dstPath)
	    mbSize = (os.path.getsize(os.path.join(dstPath, nameOfCurrentFile)))//1024//1024
	    message += "Скопирован файл {0}. Обьем файла: {1} Мб<br/>".format(nameOfCurrentFile,  mbSize)
	except IOError, e:
	    message += "Ошибка копирования файла: %s" % e + "<br/>"
    else:
	message += "Файл: " + srcFilePath +  " для копирования не найден" + "<br/>"
    if (os.path.exists(srcPath + oldFileName)):
	message += "Файл для удаления на vgok-fs-001: " + srcPath + oldFileName + " найден" + "<br/>"
	try:
	    os.remove(srcPath + oldFileName)
	    message += "Удален файл " + srcPath + oldFileName + "</br>"
	except OSError, e:
	    message += "Ошибка удаления файла: %s" % e + "<br/>"
    else:
	message += "Файл: " + srcPath + oldFileName + " для удаления на vgok-fs-001 не найден" + "<br/>"
    if (os.path.exists(dstPath + oldFileName)):
	message += "Файл для удаления на oes4: " + dstPath + oldFileName + " найден" + "<br/>"
	try:
	    os.remove(dstPath + oldFileName)  
	    message += "Удален файл " + srcPath + oldFileName + "</br>"
	except OSError, e:
	    message += "Ошибка удаления файла: %s" % e + "<br/>"
    else:
	message += "Файл :" + dstPath + oldFileName + "  для удаления на oes4 не найден" + "<br/>"

#Получение списка файлов в архивной папке вместе с их размерами и датой изменения
submessage = "<h3>Список файлов в директории /u01/backups/gal81/arch на oes4</h3><table cellpadding='5' width='35%'><tr><th align='left'>Имя файла</th><th align='left'>Размер в МБ</th><th align='left'>Время изменения</th></tr>"
names = os.listdir(archDstPath)
for name in names:
    fullname = os.path.join(archDstPath, name)
    if os.path.isfile(fullname):
	mbSize = (os.path.getsize(fullname))//1024//1024
	modifyTime = datetime.fromtimestamp(os.path.getmtime(fullname))
	submessage += "<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>".format(name, mbSize, modifyTime.strftime("%Y-%m-%d %H:%M"))
submessage += "</table>"
message += submessage

msg = MIMEMultipart('alternative')
msg.set_charset("utf-8")
msg['Subject'] = "Дублирующее копирование Галлактики от %s" % strDate
msg['From'] = "backup@vgok.ru"
msg['To'] = "petr.konev@vgok.ru"
msg['Content-Type'] = "text/html; charset=utf-8"
message += "</html>"
part = MIMEText(message, 'html', 'utf-8')
msg.attach(part)

s = smtplib.SMTP('vgok-mail.vgok.ru')
s.sendmail("backup@vgok.ru", "petr.konev@vgok.ru", msg.as_string())
s.quit()
