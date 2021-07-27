import sys
import os
import json
import smtplib
import datetime

dist_code = 664
age_lim = 18
# date_req = sys.argv[1]
date_req = '22-05-2021'
capacity_cutoff = 0

# SUPPORT_FILE_LOC = <INSERT PATH TO STORE SUPPORTING FILES>

f = open("{}response_{}.txt".format(SUPPORT_FILE_LOC, date_req), "r")
resp = f.read()
f.close()

out = []
for dict1 in json.loads(resp)['centers']:
    for dict2 in dict1['sessions']:
        if dict2['min_age_limit']==age_lim and dict2["available_capacity"]>capacity_cutoff and datetime.datetime.strptime(dict2['date'], "%d-%m-%Y")>=datetime.datetime.strptime(date_req, "%d-%m-%Y"):
            out.append(dict1)

if out:
    msg = "slots available at:\n"
    for e in out:
        tmp_str = "{} - {}".format(e['name'], e['fee_type'])
    
        for e2 in e['sessions']:
            tmp_str = "{}\nDate : {}; Capacity : {}; Vaccine : {}".format(tmp_str, e2['date'], e2['available_capacity'], e2['vaccine'])
            
        msg = msg + tmp_str + "\n\n"

    msg = msg + "\n" + "Register - https://selfregistration.cowin.gov.in"


    # sent_from = <ENTER EMAIL ADDRESS TO USE FOR SENDING OUT ALERTS>
    # to = [<ENTER LIST OF RECEIPIENTS' EMAIL ADDRESSES>]
    subject = '[ALERT] CoWin Slots Available for {}+, {} onwards'.format(age_lim, datetime.date.today().strftime("%d-%m-%Y"))

    email_text = "From: {}\r\nTo: {}\r\nSubject: {}\r\n""\r\n{}".format(sent_from, to, subject, msg)

    server_ssl = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    # server_ssl.login(sent_from, <PASSWORD FOR SENDING EMAIL ADDRESS>)
    server_ssl.sendmail(sent_from, to, email_text)
    server_ssl.close()

    with open("{}_SUCCESS_{}".format(SUPPORT_FILE_LOC, datetime.date.today().strftime("%d-%m-%Y")), "w") as f:
        f.write(resp)