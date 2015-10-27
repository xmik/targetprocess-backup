#!/bin/bash

# DATE=`date +%Y-%m-%d`
BACKUP_DIR="/tmp/tp_backup"

mkdir -p $BACKUP_DIR

ID_RANGES_STARTS[0]='1'
ID_RANGES_STARTS[1]='1000'
ID_RANGES_STARTS[2]='2782'
#ID_RANGES_STARTS[3]='3000'

# loop through the above array with ID_RANGES_STARTS
for i in "${ID_RANGES_STARTS[@]}"
do
  RANGE_START="$i"
  RANGE_END=$(($RANGE_START + 9))  # here we add 999 to RANGE_START
  BACKUP_FILE="$BACKUP_DIR/features_${RANGE_START}_${RANGE_END}.json"
  echo "Backuping features from: $RANGE_START to: $RANGE_END into $BACKUP_FILE"
  nodejs entities/features.js ${RANGE_START} ${RANGE_END} > ${BACKUP_FILE}
done

# all but: context (there is only one), take all at once (there are very few of them and should not grow): attahcments, processes, custom_rules, programs, projects, roles, teams, team_projects, workflows

# nodejs user_stories.js 1 999 > $BACKUP_DIR/user_stories_1_999.json
# nodejs user_stories.js 1000 1999
# nodejs user_stories.js 2000 2999
# nodejs user_stories.js 3000 3999
# nodejs user_stories.js 4000 4999
# nodejs user_stories.js 5000 5999
# nodejs user_stories.js 6000 6999
# nodejs user_stories.js 7000 7999
# nodejs user_stories.js 8000 8999
# nodejs user_stories.js 9000 9999
# nodejs user_stories.js 10000 10999

# Only <60 of them (27th October 2015)
# nodejs entities/attachments.js >> /tmp/tp_attachments.json
