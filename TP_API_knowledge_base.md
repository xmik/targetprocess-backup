## TP API knowledge base
How to construct TP REST API requests using NodeJS library: [`tp-api`](https://github.com/8bitDesigner/tp-api) (written in JavaScript) and plain `curl`. With example outputs.

Public sources:
* http://dev.targetprocess.com/rest/response_format
* http://dev.targetprocess.com/rest/resource
* https://md5.tpondemand.com/api/v1/index/meta
* while https://md5.tpondemand.com/api/v1/UserStories/ says what can be requested from a UserStory, this link: https://md5.tpondemand.com/api/v1/UserStories/ provides an example XML response. Same for other entities. The response contains: `Values` (e.g. Name, Description, Tags), `Resource reference`s and from `Resource collections` only CustomFields.
* https://github.com/8bitDesigner/tp-api

### Set credentials
For `curl` set:
```bash
TP_DOMAIN="mydomain.tpondemand.com"
TP_USER="me"
TP_PASSWORD="TODO"
```
For `tp-api`:
```javascript
var tp = require('tp-api')({
           domain:   'mydomain.tpondemand.com',
           username: 'me',
           password: 'TODO'
         })
```

### General problems

1. I had a problem with `curl` when using >1 parameter (using ampersands): **only the first parameter is respected**! (Or did I miss something?)
Also, when there are [] in URL ([source](http://stackoverflow.com/questions/8333920/passing-a-url-with-brackets-to-curl)), you have to use curl `-g` option; when there are () in URL you have to take the URL in "".
2. This TP API filter is misleading:
```
Find in list --> Id in (2782,2785)
```
**It does not list all the features in the range 2782-2785, but only 2 features: 2782 and 2785. If 2785 is not a feature, only 2782 is returned.**

    This is TargetProcess (not `tp-api`) bug or feature. I checked also with `curl`:
    ```
    curl -X GET -g -u $TP_USER:$TP_PASSWORD "http://$TP_DOMAIN/api/v1/Features?where=(Id%20in%20(2782,2784))"
    ```
    Instead, use: `'(Id gte 2782) and (Id lte 2785)'`.

### Example requests
#### Get 1 user story with specified ID
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/v1/UserStories/7517?format=json
```

```javascript
tp('UserStories')
  .where('Id eq 7517')
  .then(function(err, tickets) {
    console.log('Tickets:', JSON.stringify(tickets))
    console.error('Errors from the request: ', err)
  }
)
```

#### Get all user stories but decide to "take" 1
Should return the same as above example (only the request is a little different).

Returns XML anyways:
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/v1/UserStories?take=1&format=json
```

```javascript
tp('UserStories')
  .take(1)
  .then(function(err, tickets) {
    console.log('Tickets:', JSON.stringify(tickets))
    console.error('Errors from the request: ', err)
  }
)
```

#### Get 1 user story with specified ID and additional fields
Returns XML anyways:
```bash
# -g to turn off curl globbing, to allow [] usage
# http://stackoverflow.com/questions/8333920/passing-a-url-with-brackets-to-curl
curl -X GET -u $TP_USER:$TP_PASSWORD -g https://$TP_DOMAIN/api/v1/UserStories/7517?append=[Bugs-Count,Tasks-Count,Comments-Count]&format=json
```

```javascript
tp('UserStories')
  .where('Id eq 7517')
  .append('Bugs-Count, Tasks-Count, Comments-Count')
  .then(function(err, tickets) {
    console.log('Tickets:', JSON.stringify(tickets))
    console.error('Errors from the request: ', err)
  }
)
```

#### Get a collection of Entities for a specified Entity
Example: get Comments of a UserStory, (see other [collections of a UserStory](https://md5.tpondemand.com/api/v1/UserStories/meta), like e.g. MasterRelations, SlaveRelations, Times).
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD -g https://$TP_DOMAIN/api/v1/UserStories/7517/Comments?format=json
```
In the case of backup, I think it would be inefficient to request for Entities of each Entity, because we'd have to specify that explicitly: that we want Comments of a UserStory with ID 7517. Also, we'd have to know what kind of Entity we're backuping now, since e.g. Relation Entity does not have a collection of Comments.

Using tp-api, we can get many Collections of a User Story with:
```javascript
tp('UserStories')
  .take(1)
  .where('Id eq 7517')
  // AssignedUser is the Worker(s), those are not in the response by default:
  .pluck('AssignedUser, Assignments, Times, AssignedEfforts')
  .sortByDesc('NumericPriority')
  .then(function(err, entities) {
    console.log(JSON.stringify(entities))
    console.error('Errors from the request: ', err)
  }
)
```
but then all of the default fields from response are not returned, only the once listed here (plucked). This makes sense for AssignedUser, because it returns an array of users, but in ohter cases (e.g. Times) it returns an array of IDs. So anyway, we still need to get e.g. `tp('Times')` to see how much time was spent and the description. Furthermore, this approach would demand to list all the collections explicitly, thus I prefer to get default response. We'll anyway request for entities like: Times separately.

Another reason, why not use this: I think it creates **additional request for each user story** to get its 1 Collection of Entities. So it is **inefficient** and could easily go above 1000 items in a request: "You can not have more then 1000 items per request. If you set 'take' parameter greater than 1000, it will be treated as 1000 (including link generation)". [source](http://dev.targetprocess.com/rest/response_format). Furthermore, I don't think such a solution would be easier to restore (in the future).

However, it makes sense to use the `.append('Bugs-Count)` method, so that we can perform some validation when restoring (and mathing UserStory Collections Entities to a UserStory).

#### Get storage names (boards, views)
Links:
* http://dev.targetprocess.com/rest/storage
* https://md5.tpondemand.com/api/docs/views/v1/index.aspx

I think we'll use this to get all the views:
```bash
curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/views/v1/?format=json
```
They wrote "Note that only board views are supported at the moment, and nested groups are not supported at all". The response contained all the views, reports and groups, but no dashboards (but dashboards are made of views/reports).

-----


Other possible requests:
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/storage/v1?format=json
{"items":["boardGroups","boards","boardTemplateGroups","boardTemplates","burnDownVer2Filter","entityFilter","hierarchyLists","listOrderings","reports","settings","tauboard_user_shares_15"]}
```

```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/storage/v1/boards?format=json
{"items":[{"key":"5291677950073595814","ownerIds":[1],"ownerId":1,"scope":"Public"},{"key":"4747752065641711467","ownerIds":[1],"ownerId":1,"scope":"Public"},{"key":"5584704435130084206","ownerIds":[1],"ownerId":1,"scope":"Private"} # ... and other
```

But if we take only 2 boards, the output contains: "next":
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/storage/v1/boards/?Take=2&format=json
{"next":"http://mydomain.tpondemand.com:80/storage/v1/boards/?where=&select=new (Key, OwnerIds, OwnerId, Scope)&take=2&skip=2","items":[{"key":"5291677950073595814","ownerIds":[1],"ownerId":1,"scope":"Public"},{"key":"4747752065641711467","ownerIds":[1],"ownerId":1,"scope":"Public"}]}
```

```bash
curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/storage/v1/boards/5291677950073595814?format=json
```

### [Context](http://dev.targetprocess.com/rest/context)
We could use it to: retrieve list of entities for specific projects.
```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/v1/Context/?format=json
{"Acid":"8B96EDD0C14DCF5CF81F4A331475B7E1","Edition":"Pro","Version":"3.7.10.20503","AppContext":{"ProjectContext":{"No":false},"TeamContext":{"No":true}},"Culture":{"Name":"en-US","TimePattern":"g:i A","ShortDateFormat":"M/d/yyyy","LongDateFormat":"dddd, MMMM d, yyyy","DecimalSeparator":".","CurrencyDecimalSeparator":".","CurrencyDecimalDigits":2,"CurrencyGroupSeparator":","},"LoggedUser":{"ResourceType":"User","Kind":"User","Id":15,"FirstName":"Ewa", # ...
```
There is also info about Processes (with their Entity kinds and CustomFields names) and Projects (names, belonging to a Process)

```javascript
tp('Context')
  .then(function(err, entities) {
    console.log('entities:', JSON.stringify(entities))
    console.error('Errors from the request: ', err)
  }
)
```

However there is no sense in getting e.g. contextualized information about UserStory, because it contains a lot of information from Context and would be the same for all the UserStories in the same TP project:
```bash
curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/v1/Context/?ids=7517&format=json
```

### Attachments
I'll use here Attachment of Id=22, because it is a plain txt file, easy for tests

```bash
$ curl -X GET -u $TP_USER:$TP_PASSWORD https://$TP_DOMAIN/api/v1/Attachments/22?take=1
<Attachment Id="22" Name="brutus_3_2_0_swapper.txt">
  <Description>brutus_3_2_0_swapper.txt</Description>
  <Date>2014-12-18T04:31:35</Date>
  <MimeType>text/plain</MimeType>
  <Uri>https://mydomain.tpondemand.com/Attachment.aspx?AttachmentID=22</Uri>
  <ThumbnailUri>https://mydomain.tpondemand.com/AttachmentThumbnail.aspx?AttachmentID=22&amp;width=100&amp;height=100</ThumbnailUri>
  <Size>17394</Size>
  <Owner ResourceType="GeneralUser" Id="15">
    <FirstName>Ewa</FirstName>
    <LastName>Czechowska</LastName>
  </Owner>
  <General ResourceType="General" Id="4516" Name="Brutus initial stability issues" />
  <Message nil="true" />
</Attachment>
```

Here, we need to parse the response. Then you can download the attachment, the `-O` option is needed to save to file:
```bash
curl -X GET -u $TP_USER:$TP_PASSWORD -O https://mydomain.tpondemand.com/Attachment.aspx?AttachmentID=22
```
It will be saved under pretty name: `Attachment.aspx?AttachmentID=22`. Use this command to save it under custom name:
```bash
curl -X GET -u $TP_USER:$TP_PASSWORD -o brutus_3_2_0_swapper.txt https://mydomain.tpondemand.com/Attachment.aspx?AttachmentID=22
```

I suggest to first get all the attachments list and then parse the response(s) and download each attachment separately.

```javascript
tp('Attachments')
  .take(1)
  .then(function(err, entities) {
    console.log(JSON.stringify(entities))
    console.error('Errors from the request: ', err)
  }
)
```

### Assignables
Base entity for User Story, Task, Bug, Test Plan Run, Feature, Request. Do not use it, as e.g. if an Assignable is found to be a Task, the request will not return information about its UseStory. Also, you cannot `.append(Tasks-Count)` here, because Assignable may be a Task, and such request returns error.

### Other `.where()` examples
```
.where("EntityState.Name eq 'Open'")
.where("CreateDate gt '24-Oct-2015'")
.where('(Id gte 5000) and (Id lte 5010)')
```
