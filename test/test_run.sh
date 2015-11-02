#!/bin/bash
# Test if credentials are set and if environment is set

set -e

# http://mywiki.wooledge.org/BashFAQ/028
# step into the directory with this script in order to use relative
# paths to other scripts
cd "${BASH_SOURCE%/*}" || exit

if [ -f "../credentials.sh" ]; then
  source "../credentials.sh"
fi

"../verify_credentials.sh"

# generate js file with credentials
echo "var tp = require('tp-api')({
           domain:   '$TP_DOMAIN',
           username: '$TP_USER',
           password: '$TP_PASSWORD'
         })


// export the variable
// http://stackoverflow.com/questions/3922994/share-variables-between-files-in-node-js
exports.tp = tp;
" > "../credentials.js"

BACKUP_FILE="/tmp/tp_backup/test.json"
nodejs ../entities/features.js 2700 3000 > $BACKUP_FILE

echo "Success, downloaded features of ids: 2700 to 3000 into $BACKUP_FILE"
