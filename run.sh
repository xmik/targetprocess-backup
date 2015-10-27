#!/bin/bash
set -e

BACKUP_DIR="/tmp/tp_backup"

source "./credentials.sh"
"./verify_credentials.sh"

mkdir -p $BACKUP_DIR

# Download metadata about those entities in many requests (each containing less
# than 1000 items), because there are a lot of those entities objects.
ID_RANGES_STARTS[0]='1'
ID_RANGES_STARTS[1]='902'
ID_RANGES_STARTS[2]='1803'
ID_RANGES_STARTS[3]='2704'
ID_RANGES_STARTS[4]='3605'
ID_RANGES_STARTS[5]='4506'
ID_RANGES_STARTS[6]='5407'
ID_RANGES_STARTS[7]='6308'
ID_RANGES_STARTS[8]='7209'
ID_RANGES_STARTS[9]='8110'
ID_RANGES_STARTS[10]='9011'
ID_RANGES_STARTS[11]='9912'
ID_RANGES_STARTS[12]='10813'
ID_RANGE_INCREMENT='900'

declare -a ENTITIES=("assignments" "bugs" "builds" "comments" "epics" "features" "impediments" "iterations" "relations" "releases" "requests" "tasks" "team_iterations" "times" "user_stories")

# loop through the above array with ENTITIES
for e in "${ENTITIES[@]}"
do
  ENTITY="$e"
  echo "Backuping up $ENTITY"
  # loop through the above array with ID_RANGES_STARTS
  for i in "${ID_RANGES_STARTS[@]}"
  do
    RANGE_START="$i"
    RANGE_END=$(($RANGE_START + $ID_RANGE_INCREMENT))  # here we add $ID_RANGE_INCREMENT to $RANGE_START
    BACKUP_FILE="$BACKUP_DIR/$ENTITY_${RANGE_START}_${RANGE_END}.json"
    echo "Backuping $ENTITY from: $RANGE_START to: $RANGE_END into $BACKUP_FILE"
    # comment the line below for dry run
    #nodejs entities/$ENTITY.js ${RANGE_START} ${RANGE_END} > ${BACKUP_FILE}
  done
done

# Download metadata about those entities all at once (e.g. all roles at once),
# because there are very few of them and should never grow.
# Only <60 attachments (27th October 2015)
declare -a SMALL_ENTITIES=("attachments" "context" "custom_rules" "processes" "programs" "projects" "roles" "teams" "team_projects" "workflows")
for e in "${SMALL_ENTITIES[@]}"
do
  SMALL_ENTITY="$e"
  BACKUP_FILE="$BACKUP_DIR/$SMALL_ENTITY.json"
  echo "Backuping up $SMALL_ENTITY into $BACKUP_FILE"
  # comment the line below for dry run
  #nodejs entities/$SMALL_ENTITY.js > ${BACKUP_FILE}
done

VIEWS_BACKUP_FILE="$BACKUP_DIR/views.json"
echo "Backuping up views into $VIEWS_BACKUP_FILE"
# comment the line below for dry run
# curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/views/v1/?format=json > ${BACKUP_FILE}
# comment the line below for dry run
# ./download_attachments.sh $BACKUP_DIR
