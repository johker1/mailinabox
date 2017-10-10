    import smtplib
	# Import the email modules we'll need
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        # Open a plain text file for reading.  For this example, assume that
        # the text file contains only ASCII characters.
        with open("/", 'rb') as fp:
                # Create a text/plain message
                msg = MIMEText(fp.read(),"plain","utf-8")
        # me == the sender's email address
        # you == the recipient's email address
        msg['Subject'] = 'The contents of %s'
        msg['From'] = 'team@cloudfirst.pt'
        msg['To'] = email

        # Send the message via our own SMTP server, but don't include the
        # envelope header.
        s = smtplib.SMTP('localhost')
        s.sendmail('team@cloudfirst.pt', [email], msg.as_string())
        s.quit()
