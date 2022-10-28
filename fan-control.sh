#!/usr/local/bin/bash

SCRIPT_DIR=/home/brandon/scripts/fanspeed
LOG_FILE=$SCRIPT_DIR/fanspeed.log
DATE=$(date +%Y-%m-%d-%H:%M:%S)
SET_SPEED="16" # This is number 16 in percentage of fan speed. 16% speed works well for me being quiet enough. See README for more info.
SENSOR_NAME="Temp"
MAX_TEMP="37"

log () {
    echo "[$DATE] $1" >> $LOG_FILE
}

log ""
echo $(date) >> $LOG_FILE

if [ ! -f $SCRIPT_DIR/idrac-creds.sh ]; then
        echo "IDRAC credentials file not found...aborting"
        exit 0
    else
        source $SCRIPT_DIR/idrac-creds.sh
fi


DEC_HEX=$(printf '%x\n' $SET_SPEED)

TEMP=$(ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_UNAME -P $IDRAC_PASSWD sdr type temperature)
log "$TEMP"
TEMP=$(echo $TEMP | grep -m 1 "$SENSOR_NAME")
TEMP=$(echo $TEMP | awk '{ print $21 }')

log "$IDRAC_IP: temp is $TEMP degrees C"
if [[ $TEMP > $MAX_TEMP ]]
  then
    log "Getting hot in here - enabling dynamic mode"
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_UNAME -P $IDRAC_PASSWD raw 0x30 0x30 0x01 0x01
  else
    log "Temps are less than $MAX_TEMP degrees C ...setting fan speed to $SET_SPEED%"
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_UNAME -P $IDRAC_PASSWD raw 0x30 0x30 0x01 0x00
    ipmitool -I lanplus -H $IDRAC_IP -U $IDRAC_UNAME -P $IDRAC_PASSWD raw 0x30 0x30 0x02 0xff 0x$DEC_HEX
    sleep 1
    log "Setting applied"
fi
