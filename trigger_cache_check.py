import sys
import os
import json
import smtplib
import datetime

f = open(sys.argv[1], "r")
headers = f.read().split("\n")
f.close()

for e in headers:
    key_val = e.split(": ")
    if len(key_val) == 2:
        if key_val[0]=="x-cache":
            if key_val[1] != "Miss from cloudfront":
                # sent_from = <ENTER EMAIL ADDRESS TO USE FOR SENDING OUT ALERTS>
                # to = [<ENTER LIST OF RECEIPIENTS' EMAIL ADDRESSES>]
                subject = '[CACHE ALERT] CACHE DETECTED AT REQUEST ID %s'%(sys.argv[2])
                msg = "Header - \n%s"%(headers)
                email_text = "From: %s\r\nTo: %s\r\nSubject: %s\r\n""\r\n%s"%(sent_from, to, subject, msg)
                server_ssl = smtplib.SMTP_SSL('smtp.gmail.com', 465)
                # server_ssl.login(sent_from, <PASSWORD FOR SENDING EMAIL ADDRESS>)
                print("Mail trigger from 'cache check' at request ID -  %s"%(sys.argv[2]))
                server_ssl.sendmail(sent_from, to, email_text)
                server_ssl.close()

            break




