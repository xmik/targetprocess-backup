var tp = require('tp-api')({
           domain:   'mydomain.tpondemand.com',
           username: 'me',
           password: 'TODO'
         })


// export the variable
// http://stackoverflow.com/questions/3922994/share-variables-between-files-in-node-js
exports.tp = tp;
