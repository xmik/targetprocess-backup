# targetprocess-backup

Backup TargetProcess entities.

## What it does
This project backups TargetProcess entities like: user stories, features and saves information about them in `.json` files. It also downloads attachments. Uses TargetProcess REST API.

### Backup directory structure
Backup will be done into `/tmp/tp_backup/full`.
```
/tmp/tp_backup/full/
  attachments/
    my_attachment1.png          # here goes real name of your attachment
    my_attachment2.txt
  assignments_1_901.json        # metadata about attachments
  assignments_902_1802.json
  assignments_1803_2703.json
  ...
  attachments.json
  bugs_1_901.json
  bugs_902_1802.json
  ...
  builds_1_901.json
  ...
  context.json
  ...
```
The entities objects are sorted in descending order (except for Attachments for which that option does not work and there is a [public issue](https://tp3.uservoice.com/forums/174654-we-will-rock-you/suggestions/6312209-improve-rest-api-support-operations-for-attachmen) for that).
For each entity type which is backuped, there is a javascript file in `./entities` directory. Additionally: all the views are backuped using `curl`.

### The entities not backuped
Dashboards are not backuped. But they are made of views, reports and groups (directories), which are backuped.

## Usage
### Without Docker
#### Environment
Set up the environment:
```
$ sudo apt-get install curl
$ curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
$ sudo apt-get install nodejs npm wget
```
Then, clone this repository. In the directory where you cloned this repository, run:
```
$ npm install tp-api@1.0.6
```

#### Run
Run the main backup script, passing the credentials as environment variables. Use some user who is a TargetProcess Admin.:
```
$ TP_USER=me TP_DOMAIN=mydomain.tpondemand.com TP_PASSWORD=TODO ./run.sh
```
If you don't like passing your credentials as environment variables, you can instead create a local file: `./credentials.sh`, example:
```
#!/bin/bash

export TP_DOMAIN="mydomain.tpondemand.com"
export TP_USER="me"
export TP_PASSWORD="TODO"
```
and run the script:
```
$ ./run.sh
```

#### Test run
Instead of running the full backup, you can invoke a bash script which  downloads metadata about some TargetProcess features. Use it in order to test if your environment is correctly set and if you can connect to TargetProcess API.
```
$ TP_USER=me TP_DOMAIN=mydomain.tpondemand.com TP_PASSWORD=TODO ./test/test_run.sh
```

Result will be saved to: `/tmp/tp_backup/test`
### With Docker
1. Build the image:
```
tp_backup$ docker build -t "targetprocess-backup:$(cat version.txt)" .
```
2. Run the image:
```
docker run -ti --volume=/tmp/tp_backup:/tmp/tp_backup --env TP_DOMAIN="mydomain.tpondemand.com" --env TP_USER="me" --env TP_PASSWORD="TODO" targetprocess-backup:$(cat version.txt)
```

To test the docker image and not run the full backup:
```
docker run -ti --volume=/tmp/tp_backup:/tmp/tp_backup --env TP_DOMAIN="mydomain.tpondemand.com" --env TP_USER="me" --env TP_PASSWORD="TODO" targetprocess-backup:$(cat version.txt) /opt/tp_backup/test/test_run.sh
```

### Output
Anywhere you see:
```
Errors from the request:  null
```
that means there were no errors from a REST API request.

### Tar
To compress the backup:
```
$ cd /tmp
/tmp$ tar -czf tp_backup-$(date +%Y-%m-%d).tar.gz tp_backup/
```

### Verification
An easy test is to use the `jq` program, which is downloaded by `run.sh`, so it should be in the current directory after backuping.

To get all the IDs of some entity objects in a file:
```
$ cat /tmp/tp_backup/full/features_2704_3604.json | ./jq '.[].Id'
```
To get names:
```
$ cat /tmp/tp_backup/full/features_6308_7208.json | ./jq '.[].Name'
```

### Details
*You don't have to read it if you only want to create backup*

#### Backup only Features
Each entity type that will be backuped has its own file in `./entities` directory. Example file is: `./entities/features.js`. That file takes 2 command line parameters: the start ID and the end ID. They specify a range (inclusive) in which we look for entity objects. Each of those files in `./entities` directory can be invoked separately. For example, to backup features of IDs from 100 to 150, run:
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
Some of those files do not take parameters, because there are so few of such entities objects (e.g. we have 2 Roles) and we backup them all at once.

#### Why the ranges
As written on [dev.targetprocess.com](http://dev.targetprocess.com/rest/response_format): "You can not have more then 1000 items per request. If you set 'take' parameter greater than 1000, it will be treated as 1000 (including link generation)". Also, despite of Features, Tasks, UserStories and similar entities sharing the same Id assignments, the entities like e.g.: Assignments has its own Ids assignments (there can be Feature with Id = 3 and Assignment with Id = 3), so to make the number even (not to backup 999 entities objects at once) and to be more safe, we backup up to 900, not 1000 entities in 1 request.

In order not to make the main script too complicated, I use those ranges for all entities for which I can. Each request response is saved to one file.

By default, a request takes 25 entities objects.

#### Why the `.append()` method
In order to make the backup restore, in the future, easier, I decided to get additional fields for some enitities objects. Example: `Bugs-Count` or `Comments-Count`. So that we can perform some verification that we matched e.g. all the Bugs for a UserStory.

#### Attachments
There is some trouble around getting Attachments (#7537 and [this open bug](https://tp3.uservoice.com/forums/174654-we-will-rock-you/suggestions/6312209-improve-rest-api-support-operations-for-attachmen)), in result we can:
  * get metadata about 1 attachment at a time using curl
  * get metadata about all attachments at a time using curl
  * get metadata about all attachments at a time using `tp-api`

Since we have less than 60 attachments (28th October 2015), it is ok to get metadata about them all at once. I don't think this will change. Each of them is downloaded separately anyway.

## Development

Please read the [TP_API_knowledge_base.md](TP_API_knowledge_base.md), it contains examples using `tp-api` and `curl`.

### Experiments
Use the file `test.js` to experiment using `tp-api`:
```
$ nodejs ./test/test.js
```
or the file `test.sh` to experiment using `curl`:
```
$ ./test/test.sh
```
Those files are intended to be standalone (not depend on any other files).

### Use newer `tp-api` version
If you want to use unreleased `tp-api` version, instead of
```
$ npm install tp-api
```
run:
```
$ mkdir -p node_modules/ && cd node_modules/
$ git clone https://github.com/8bitDesigner/tp-api.git && cd tp-api/
$ npm install
```

## License

Licensed under the MIT license. See LICENSE for details.
