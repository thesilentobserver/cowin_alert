import sys
import os
import json
import smtplib
import datetime
import glob
import time

age_lim_list = [18]
date_req = sys.argv[1]
dose_cnt = {
    18: "dose2", 
    45: "dose1"
}

vaccine = {
    18: "COVAXIN", 
    45: "COVAXIN"
}

capacity_cutoff = 5
cooldown_time = {
    18: 15,    #in minutes
    45: 30  #in minutes
}

# SUPPORT_FILE_LOC = <INSERT PATH TO STORE SUPPORTING FILES>




f = open("%sresponse_%s.txt"%(SUPPORT_FILE_LOC, sys.argv[2]), "r")
resp = json.loads(f.read())
f.close()

for age_lim in age_lim_list:
    prev_success = glob.glob("%s_SUCCESS_%s_%s_%s*"%(SUPPORT_FILE_LOC, age_lim, date_req, sys.argv[3]))
    
    open_slots = []
    if resp['sessions']:
        for sess_info in resp['sessions']:
            if sess_info['vaccine'] == vaccine[age_lim] and sess_info['min_age_limit']==age_lim and sess_info["available_capacity_" + dose_cnt[age_lim]]>capacity_cutoff:
                open_slots.append(sess_info)

    if open_slots:

        if prev_success:

            prev_time = int(prev_success[0].split(".")[0].split("_")[-1])

            if (int(time.time()) - prev_time <= cooldown_time[age_lim]*60):
                print("Slot alert for %s+ sent out less than %s minutes. Skipping alert generated due to request_ID = %s"%(age_lim, cooldown_time[age_lim], sys.argv[4]))
                continue
            else:
                os.system("rm -f %s"%(prev_success[0]))
        
        msg = "slots available at:\n"
        for slot in open_slots:
            tmp_str = "[%s] %s (%s)\nVaccine - %s\nDose 1 availability - %s\nDose 2 availability - %s"%(slot['date'], slot['name'], slot['fee_type'], slot['vaccine'], slot['available_capacity_dose1'], slot['available_capacity_dose2'])
        
            msg = msg + tmp_str + "\n\n"

        msg = msg + "\n" + "Register - https://selfregistration.cowin.gov.in"


        # sent_from = <ENTER EMAIL ADDRESS TO USE FOR SENDING OUT ALERTS>
        # to = [<ENTER LIST OF RECEIPIENTS' EMAIL ADDRESSES>]
        subject = '[ALERT] CoWin Slots Available for %s+ on %s'%(age_lim, date_req)

        email_text = "From: %s\r\nTo: %s\r\nSubject: %s\r\n""\r\n%s"%(sent_from, to, subject, msg)

        server_ssl = smtplib.SMTP_SSL('smtp.gmail.com', 465)
        # server_ssl.login(sent_from, <PASSWORD FOR SENDING EMAIL ADDRESS>)
        print("Mail triggered due to %s+ 'slot alert' at request ID - %s"%(age_lim, sys.argv[4]))
        server_ssl.sendmail(sent_from, to, email_text)
        server_ssl.close()

        with open("%s_SUCCESS_%s_%s_%s_%s"%(SUPPORT_FILE_LOC, age_lim, date_req, sys.argv[3], str(int(time.time()))), "w") as f:
            f.write(str(resp))
        
        # print("'Slot found' alert sent out at request ID - %s"%(sys.argv[4]))
