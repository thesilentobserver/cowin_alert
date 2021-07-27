import sys
import os
import json
import smtplib
import datetime

try:
    # sent_from = <ENTER EMAIL ADDRESS TO USE FOR SENDING OUT ALERTS>
    # to = [<ENTER LIST OF RECEIPIENTS' EMAIL ADDRESSES>]
    subject = '[FAILURE ALERT] ALERT JOB FAILING'
    msg = "CURRENT WAIT TIME = %s s\nConsecutive Failures : %s"%(sys.argv[1], sys.argv[2])
    email_text = "From: %s\r\nTo: %s\r\nSubject: %s\r\n""\r\n%s"%(sent_from, to, subject, msg)
    # print(msg)
    server_ssl = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    # server_ssl.login(sent_from, <PASSWORD FOR SENDING EMAIL ADDRESS>)
    print("Mail triggered due to 'failure alert'")
    server_ssl.sendmail(sent_from, to, email_text)
    server_ssl.close()
except:
    sys.exit("Couldn't send out failure alert. Exiting...")