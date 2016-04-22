# hubot-jira-reporter

Compiles data from JIRA into daily reports

See [`src/jira-reporter.coffee`](src/jira-reporter.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-jira-reporter --save`

Then add **hubot-jira-reporter** to your `external-scripts.json`:

```json
[
  "hubot-jira-reporter"
]
```

## Sample Interaction

### Show recently closed stories
```
chris>>
  hubot show jira closed stories
hubot>>
  Recently closed stories:
    AA-134 Lorem ipsum dolor sit amet, consectetur
    AA-42 Adipisicing elit, sed do eiusmod tempor incididunt
```

### Show in progress tasks
```
chris>>
  hubot show jira in progress
hubot>>
  In progress tasks:
    ​*unassigned*​, 1h remaining - Testing Unassigned Subtasks (AA-309)
        ↳ Who's working on this? https://example.atlassian.net/browse/AA/309
    alex, 2h remaining - Review plan (AA-288)
        ↳ This hasn't been updated since yesterday. https://example.atlassian.net/browse/AA-288
    alex, 3h remaining - Update necessary things (AA-306)
    anne, 7h remaining - Improve node-block performance (AA-296)
    flore, ​*0h remaining*​ - Refactor outer lateral adapter (AA-308)
        ↳ Should this be marked as Completed? https://example.atlassian.net/browse/AA-308
```

### Show free agents
```
chris>>
   hubot show jira free agents
hubot>>
  Free agents:
    chris, steven
```

### Show everything
```
chris>>
  hubot show jira report
hubot>>
  Recently closed stories:
    AA-134 Lorem ipsum dolor sit amet, consectetur
    AA-42 Adipisicing elit, sed do eiusmod tempor incididunt
  In progress tasks:
    ​*unassigned*​, 1h remaining - Testing Unassigned Subtasks (AA-309)
        ↳ Who's working on this? https://example.atlassian.net/browse/AA/309
    alex, 2h remaining - Review plan (AA-288)
        ↳ This hasn't been updated since yesterday. https://example.atlassian.net/browse/AA-288
    alex, 3h remaining - Update necessary things (AA-306)
    anne, 7h remaining - Improve node-block performance (AA-296)
    flore, ​*0h remaining*​ - Refactor outer lateral adapter (AA-308)
        ↳ Should this be marked as Completed? https://example.atlassian.net/browse/AA-308
  Free agents:
    chris, steven
  ```
