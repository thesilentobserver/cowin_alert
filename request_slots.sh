#!/bin/bash

CURR_DT=`date +"%d-%m-%Y"`
DIST_CD=664
wait_time=1
counter=0
# SUPPORT_FILE_PATH=<INSERT PATH TO STORE SUPPORTING FILES>
# CODE_FILE_PATH=<INSERT PATH TO CORE CODE FILES>
# Location to use for VPN
LOCATION=in
REQ_COUNTER=0

expressvpn disconnect
systemctl restart network-manager
expressvpn connect $LOCATION

if [ ! -f "$SUPPORT_FILE_PATH/request_log.txt" ]; then
    touch $SUPPORT_FILE_PATH/request_log.txt
fi

if [ ! -f "$SUPPORT_FILE_PATH/request_fail_log.txt" ]; then
    touch $SUPPORT_FILE_PATH/request_fail_log.txt
fi

while : 
do
    if [ ! -f "$SUPPORT_FILE_PATH/_SUCCESS_${CURR_DT}" ]; then

        REQ_COUNTER=$(( $REQ_COUNTER + 1 ))
        
        if [[ ${REQ_COUNTER}%10 -eq 0 ]]; then
            resp_cd=`curl -v -w  "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36" -X GET "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=${DIST_CD}&date=${CURR_DT}&" -H  "accept: application/json" -H  "Accept-Language: hi_IN" -o "$SUPPORT_FILE_PATH/response_log_verbose_req_ID_$REQ_COUNTER.txt"`

        else
            resp_cd=`curl -s -w  "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36" -X GET "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=${DIST_CD}&date=${CURR_DT}&" -H  "accept: application/json" -H  "Accept-Language: hi_IN" -o "$SUPPORT_FILE_PATH/response.txt"`
        fi

        echo "$REQ_COUNTER `date` ---- HTTP RESPONSE CODE:${resp_cd}" >> $SUPPORT_FILE_PATH/request_log.txt

        if [ "$(( $(wc -l <$SUPPORT_FILE_PATH/request_log.txt) ))" -gt 10080 ]; then
            tail -n 10080 $SUPPORT_FILE_PATH/request_log.txt > $SUPPORT_FILE_PATH/request_log_trunc.txt
            rm $SUPPORT_FILE_PATH/request_log.txt
            mv $SUPPORT_FILE_PATH/request_log_trunc.txt $SUPPORT_FILE_PATH/request_log.txt
        fi
        
        if [ ${resp_cd} -eq 200 ]; then
            python3 $CODE_FILE_PATH/trigger_slot_alert.py
            counter=0
            wait_time=1
            
            # If slot found, sleep till next day
            if [ -f "$SUPPORT_FILE_PATH/_SUCCESS_${CURR_DT}" ]; then
                current=$(date -d "now" "+%s")
                midnight=$(date -d "tomorrow 00:00:00" "+%s")
                echo "Slot found today! Sleeping Till next day... "
                sleep $(( midnight-current))s
            fi

        else
            echo "$REQ_COUNTER `date` ---- HTTP RESPONSE CODE:${resp_cd}" >> $SUPPORT_FILE_PATH/request_fail_log.txt
            counter=$(( $counter + 1 ))
            if [[ ${resp_cd} -eq 000 || ${counter}%5 -eq 0 ]]; then
                echo "Reconnecting network..."
                expressvpn disconnect
                systemctl restart network-manager
                expressvpn connect $LOCATION
            fi
            
            if [[ $counter%5 -eq 0 ]]; then
                # wait_time=$(( $wait_time * 2))
                python3 $CODE_FILE_PATH/trigger_failure_alert.py "$wait_time" "$counter"
            fi
        fi
    fi

    # echo "waiting for ${wait_time} minutes..."
    sleep ${wait_time}m
done