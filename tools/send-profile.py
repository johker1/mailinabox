#!/usr/bin/python3

import smtplib, sys
# Import the email modules we'll need
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
# Open a plain text file for reading.  For this example, assume that
# the text file contains only ASCII characters.
with open("/home/ubuntu/mailinabox/tools/mensagem.txt", 'rb') as fp:
    # Create a text/plain message
    msg = MIMEMultipart(fp.read(),"plain","utf-8")
# me == the sender's email address
# you == the recipient's email address
msg['Subject'] = 'OSX e IOS MOBILE CONFIG'
msg['From'] = 'team@cloudfirst.pt'
msg['To'] = sys.argv[1]

# Attach file
filename = "/var/lib/mailinabox/mobileconfig.xml"
f = open(filename)
attachment = MIMEText(f.read())
attachment.add_header('Content-Disposition', 'attachment', filename=filename)           
msg.attach(attachment)

# Send the message via our own SMTP server, but don't include the
# envelope header.
s = smtplib.SMTP('localhost')
s.sendmail('team@cloudfirst.pt', [sys.argv[1]], msg.as_string())
s.quit()
