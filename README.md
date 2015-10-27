# TP backup

Backup TargetProcess entities.

## Usage
First, clone this repository. Then, you need to set up the environment:
```
$ sudo apt-get install nodejs
$ sudo apt-get install npm
```
This command should be ran inside the directory with this git cloned repository:
```
$ npm install tp-api
```
Run the bash script:
```
$ run.sh
```
Backup will be done in `/tmp/tp_backup`.

### Details
#### Backup only Features
Each entity type that will be backuped has its own file in `./entities` directory. Example file is: `./entities/features.js`. That file takes 2 commandline parameters: the start ID and the end ID, to specify a range (inclusive) in which we look for entities. Each of those files can be invoked separately. For example to backup features of IDs from 100 to 150, run:
```
$ nodejs entities/features.js 100 150
```
In order to redirect the stdout to a file:
```
$ nodejs entities/features.js 100 150 > /tmp/tp_features_100_to_150.json
```
There is still stderr, which if all goes fine shows:
```
Errors from the request:  null
```

#### Why the ranges
As written on [dev.targetprocess.com](http://dev.targetprocess.com/rest/response_format): "You can not have more then 1000 items per request. If you set 'take' parameter greater than 1000, it will be treated as 1000 (including link generation). ", so we backup up to 999 entities in 1 request.

In order not to make the main script to complicated, I use those ranges for all entities for which I can.

#### Why the `.append()` method
TODO
1. should I take not 1000 - 1999 but 1000 - 1997 e.g. ? (can e.g. Assignments have its own ids? -- yes they do)

// each file for 1 request, less than 1000 ids
// each of those files use (require? include?) a file with credentials
// run from bash, redirect to .json file, stderr will show errors (or null)
// never use pluck -- get default response (no includes/excludes)
// .sortByDesc('Id')
////////////////////////////////////////
#### Attachments
There is some trouble around getting Attachments (#7537 and [this open bug](https://tp3.uservoice.com/forums/174654-we-will-rock-you/suggestions/6312209-improve-rest-api-support-operations-for-attachmen)), in result we can only:
  * get metadata about 1 attachment at a time using curl
  * get metadata about all attachments at a time using curl
  * get metadata about all attachments at a time using `tp-api`
Since we have <60 attachments (27th October 2015), it is ok to take them all at once.

#### The entities to backup:
1. UserStories with its fields and CustomFields
2. TeamIterations
3. Comments
2. Context
4. Processes ?
3. Views (meaning views + groups (directories) + reports)
1. Attachments

#### The entities not backuped:
2. Dashboards (but views, reports and groups (directories) are backuped)

## Development
Please read the [TP_API_knowledge_base.md](TP_API_knowledge_base.md), it contains examples using `tp-api` and curl.
