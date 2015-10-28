# TP backup

Backup TargetProcess entities.

## Usage
First, clone this repository. Then, you need to set up the environment:
```
$ sudo apt-get install nodejs npm curl wget
```
The following command should be ran in the directory with this git cloned repository.
  * If `tp-api` 1.0.6 is already released at [www.npmjs.com](https://www.npmjs.com/package/tp-api):
  ```
  $ npm install tp-api
  ```
  * otherwise:
  ```
  $ mkdir -p node_modules/ && cd node_modules/
  $ git clone https://github.com/8bitDesigner/tp-api.git && cd tp-api/
  $ npm install
  ```

You can verify that `tp-api` is invokable by running `.test/test.js`, see [#Development#Experiments](#experiments)

Set valid credentials in `./credentials.js` and `./credentials.sh` files. Use some user who is a TargetProcess Admin.
Run the main backup script:
```
$ ./run.sh
```
Backup will be done in `/tmp/tp_backup`. Done 28th October 2015 took 6 minutes and 24MB.

### Verification
An easy test is to use the `jq` program, which is downloaded by `run.sh`, so it should be in the current directory after backuping.

To get all the IDs of some entity objects in a file:
```
$ cat /tmp/tp_backup/features_2704_3604.json | ./jq '.[].Id'
```
To get names:
```
$ cat /tmp/tp_backup/features_6308_7208.json | ./jq '.[].Name'
```

### Details
*You don't have to read it if you only want to create backup*

#### Backup directory structure
```
/tmp/tp_backup/
  attachments/
  assignments_1_901.json
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


Since we have <60 attachments (28th October 2015), it is ok to get them all at once.

#### The entities not backuped:
Dashboards are not backuped. But they are made of views, reports and groups (directories), which are backuped.


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
