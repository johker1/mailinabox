#!/usr/bin/python3

import smtplib, sys, os, uuid
from os.path import basename
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate
from shutil import copyfile

def send_mail(send_from, send_to, subject, text, file,
              server="127.0.0.1"):
    assert isinstance(send_to, list)

    msg = MIMEMultipart()
    msg['From'] = send_from
    msg['To'] = COMMASPACE.join(send_to)
    msg['Date'] = formatdate(localtime=True)
    msg['Subject'] = subject

    msg.attach(MIMEText(text))

    with open(file, "rb") as fil:
        part = MIMEApplication(
            fil.read(),
            Name=basename(file)
        )
        # After the file is closed
        part['Content-Disposition'] = 'attachment; filename="%s"' % basename("osx.mobileconfig")
        msg.attach(part)

    smtp = smtplib.SMTP(server)
    smtp.sendmail(send_from, send_to, msg.as_string())
    smtp.close()
try:
        os.remove("/var/lib/mailinabox/mobileconfig.xml.LASTSENT")
except OSError:
        pass
with open('/var/lib/mailinabox/mobileconfig.xml') as infile, open('/var/lib/mailinabox/mobileconfig.xml.LASTSENT', 'w') as outfile:
        for line in infile:
                line= line.replace('USER_EMAIL', sys.argv[1])
                line= line.replace('USER_USER', sys.argv[1].split('@')[0])
                line= line.replace('USERDOMAIN', sys.argv[1].split('@')[1])
                line= line.replace('UUID1', str(uuid.uuid4()))                
                line= line.replace('UUID2', str(uuid.uuid4()))                
                line= line.replace('UUID3', str(uuid.uuid4()))                
                line= line.replace('UUID4', str(uuid.uuid4()))                
                
                outfile.write(line)

del sys.argv[0]

send_mail("team@cloudfirst.pt",
                [sys.argv[0]],
                "OSX e IOS Profile",
                '\nPara configurar o email, calendário e contactos basta utilizar o perfil em anexo.\n'
                '1 - salvar o anexo \n'
                '2 - fazer double-click no ficheiro no anexo guardado (osx.mobileconf)\n'
                '3 - Preencha com o seu email e password em todos os campos\n\n'
                '       Obrigado e Bem Vindo!',
                "/var/lib/mailinabox/mobileconfig.xml.LASTSENT")

