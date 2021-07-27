#!/bin/bash

DIST_CD=664
wait_time=5
FAIL_COUNTER=0
# SUPPORT_FILE_PATH=<INSERT PATH TO STORE SUPPORTING FILES>
# CODE_FILE_PATH=<INSERT PATH TO CORE CODE FILES>
# Location to use for VPN
LOCATION=in
REQ_COUNTER=0
# Max logfile size
LOG_SIZE=141120

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
    # Check slots in next 14 days
    for INC in {0..14}
    do
        CURR_DT=`date +%Y-%m-%d`    
        REQ_DATE=$(date -d"$(date +%Y-%m-%d -d "$CURR_DT + $INC day")" +%d-%m-%Y)
        
        # if [ ! -f "$SUPPORT_FILE_PATH/_SUCCESS_${REQ_DATE}_${CURR_DT}" ]; then

        REQ_COUNTER=$(( $REQ_COUNTER + 1 ))
        
        if [[ ${REQ_COUNTER}%25 -eq 0 ]]; then
            resp_cd=`curl -s -w "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36" -X GET "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByDistrict?district_id=${DIST_CD}&date=${REQ_DATE}" -H  "accept: application/json" -H  "Accept-Language: hi_IN" -o "${SUPPORT_FILE_PATH}/response_${INC}.txt" -D "${SUPPORT_FILE_PATH}/header_dump.txt"`
            python3 ${CODE_FILE_PATH}/trigger_cache_check.py "${SUPPORT_FILE_PATH}/header_dump.txt" "$REQ_COUNTER"

        else
            resp_cd=`curl -s -w "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36" -X GET "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByDistrict?district_id=${DIST_CD}&date=${REQ_DATE}" -H  "accept: application/json" -H  "Accept-Language: hi_IN" -o "${SUPPORT_FILE_PATH}/response_${INC}.txt"`
        fi

        start_tm=`date +%s` 

        echo "`printf "%08d" $REQ_COUNTER`  $REQ_DATE   `date`  ----    HTTP RESPONSE CODE:${resp_cd}" >> $SUPPORT_FILE_PATH/request_log.txt

        if [ "$(( $(wc -l <${SUPPORT_FILE_PATH}/request_log.txt) ))" -gt $LOG_SIZE ]; then
            tail -n ${LOG_SIZE $SUPPORT_FILE_PATH}/request_log.txt > ${SUPPORT_FILE_PATH}/request_log_trunc.txt
            rm ${SUPPORT_FILE_PATH}/request_log.txt
            mv ${SUPPORT_FILE_PATH}/request_log_trunc.txt ${SUPPORT_FILE_PATH}/request_log.txt
        fi
        
        if [ ${resp_cd} -eq 200 ]; then
            python3 ${CODE_FILE_PATH}/trigger_slot_alert_district.py "$REQ_DATE" "$INC" "$CURR_DT" "$REQ_COUNTER"
            FAIL_COUNTER=0
            
            # # If slot found, sleep till next day
            # if [ -f "$SUPPORT_FILE_PATH/_SUCCESS_${REQ_DATE}" ]; then
            #     current=$(date -d "now" "+%s")
            #     midnight=$(date -d "tomorrow 00:00:00" "+%s")
            #     echo "Slot found today! Sleeping Till next day... "
            #     sleep $(( midnight-current))s
            # else
            #     # echo "waiting for ${wait_time} minutes..."
            #     sleep ${wait_time}m
            # fi

        else
            echo "`printf "%08d" $REQ_COUNTER`  $REQ_DT `date`  ----    HTTP RESPONSE CODE:${resp_cd}" >> ${SUPPORT_FILE_PATH}/request_fail_log.txt
            FAIL_COUNTER=$(( $FAIL_COUNTER + 1 ))
            if [ ${resp_cd} -eq 000 ]; then
                echo "`date` HTTP RESPONSE 000 encountered. Sleeping for 30s..."
                sleep 30s
            fi
            
            if [[ $FAIL_COUNTER%5 -eq 0 ]]; then
                echo "Reconnecting network..."
                expressvpn disconnect
                systemctl restart network-manager
                expressvpn connect $LOCATION
                # wait_time=$(( $wait_time * 2))
                # echo "wait time increased to ${wait_time}" 
                python3 ${CODE_FILE_PATH}/trigger_failure_alert.py "$wait_time" "$FAIL_COUNTER"
            fi

        fi

        end_tm=`date +%s`
        cooldown_time_rem=$(( $wait_time - $end_tm + $start_tm ))

        if [ $cooldown_time_rem -gt 0 ]; then
            # echo "sleeping for $cooldown_time_rem seconds..."
            sleep ${cooldown_time_rem}s
        fi

        # fi
    
    done

done
