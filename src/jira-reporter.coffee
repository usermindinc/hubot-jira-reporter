# Description
#   Compiles data from JIRA into daily reports
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Chris Downie <cdownie@gmail.com>


btoa       = require 'btoa'
# cronParser = require 'cron-parser'
moment     = require 'moment'
# schedule   = require 'node-schedule'
# Promise    = require 'promise'
# _          = require 'underscore'

jiraUrl = ->
  process.env.HUBOT_JIRA_URL
projectId = ->
  process.env.HUBOT_JIRA_PROJECT_ID
userGroup = ->
  process.env.HUBOT_JIRA_REPORT_USER_GROUP
authPayload = () ->
  username = process.env.HUBOT_JIRA_USERNAME
  password = process.env.HUBOT_JIRA_PASSWORD

  if username? and password?
    return btoa "#{username}:#{password}"
  else
    return null



# 4 questions
# 1. Does everyone have something in progress?
# 2. Does all in-progress stuff have an owner?
# 3. What *stories* have been closed in the last day?
# 4. Have all in-progress issues had their time tracking updated?

# what sprints are active?
# who's in jira?
#
# Interactions!!
# show jira closed stories
# Closed Stories:
#   * ID - Title
#   * ID - Title
#
# show jira in progress
# In Progress tasks:
#   * @assigned - 3h remaining on ID - Title
#   * @assigned - 16h remaining on ID - Title
#      \-> Not updated since yesterday. http://link
#   * *unassigned* - 30h remaining -
#
# show jira free agents
# Free agents: Sullins, Maclemnore, Lacoste
#
# show jira report
# Closed Stories:
#   * ID - Title
#   * ID - Title
# In Progress tasks:
#   * @assigned - 3h remaining on ID - Title
#   * @assigned - 16h remaining on ID - Title
#      \-> Not updated since yesterday. http://link
#   * *unassigned* - 30h remaining -
# Free agents: Sullins, Maclemnore, Lacoste



# Check if all the required environment variables have been set.
isConfiguredCorrectly = (res) ->
  errors = []

  if !jiraUrl()?
    errors.push "Missing HUBOT_JIRA_URL environment variable"
  if !process.env.HUBOT_JIRA_USERNAME?
    errors.push "Missing HUBOT_JIRA_USERNAME environment variable"
  if !process.env.HUBOT_JIRA_PASSWORD?
    errors.push "Missing HUBOT_JIRA_PASSWORD environment variable"
  if !process.env.HUBOT_JIRA_PROJECT_ID?
    errors.push "Missing HUBOT_JIRA_PROJECT_ID environment variable"

  if errors.length > 0
    res.send errors.join('\n')
    return false
  return true

getFromJira = (robot, path, callback) ->
  robot.http("#{jiraUrl()}#{path}")
    .header('Authorization', "Basic #{authPayload()}")
    .get() callback

fetchAndGenerate = (robot, fetchMethod, generateMethod) ->
  fetchMethod(robot)
    .then (results) ->
      generateMethod(results)
    .catch (error) ->
      "Whoops. #{error.message}"
#
# All fetch* methods return promises. They make calls to get specific data from the JIRA api.
#
fetchSprints = (robot) ->
  sprintsJql = "project = #{projectId()} and Sprint not in closedSprints()"
  requestUrl = "/rest/greenhopper/1.0/integration/teamcalendars/sprint/list?jql=#{sprintsJql}"

  return new Promise (resolve, reject) ->
    getFromJira robot, requestUrl, (err, resp, body) ->
      try
        bodyObj = JSON.parse(body)
        sprints = bodyObj.sprints || []
        resolve sprints
      catch error
        reject error

fetchUser = (robot, user) ->
  requestUrl = "/rest/api/2/user?key=#{user.key}&expand=groups"

  return new Promise (resolve, reject) ->
    getFromJira robot, requestUrl, (err, resp, body) ->
      try
        user = JSON.parse(body)
        resolve user
      catch error
        reject error

fetchUsers = (robot) ->
  # The correct way to get users by a group is with the /group?groupname=developers API.
  # Unfortunately, that requires the caller to have admin priviledges. This makes tons of
  # calls to the /user api to filter down to the userGroup, if it exists.
  requestUrl = "/rest/api/2/user/assignable/search?project=#{projectId()}"

  return new Promise (resolve, reject) ->
    getFromJira robot, requestUrl, (err, resp, body) ->
      try
        users = JSON.parse(body)

        if userGroup()?
          # Filter by userGroup if it exists
          userPromises = users.map (user) ->
            return fetchUser(robot, user)
          Promise.all(userPromises)
            .then (users) ->
              filteredUsers = users.filter (user) ->
                groups = user.groups.items || []
                groups.find (group) ->
                  group.name == userGroup()

              resolve filteredUsers
            .catch (error) ->
              reject error
        else
          resolve users
      catch error
        reject error

fetchInProgressSubtasks = (robot) ->
  fetchSprints(robot)
    .then (sprints) ->
      sprintIds = sprints.map( (sprint) -> sprint.id ).join(',')
      jql = "project in (#{projectId()}) AND issuetype in subTaskIssueTypes() AND status = \"In Progress\" AND Sprint in (#{sprintIds})"
      requestUrl = "/rest/api/2/search?jql=#{jql}"

      new Promise (resolve, reject) ->
        getFromJira robot, requestUrl, (err, resp, body) ->
          try
            bodyObj = JSON.parse(body)
            issues = bodyObj.issues || []
            resolve issues
          catch error
            reject error

fetchRecentlyClosedStories = (robot) ->
  fetchSprints(robot)
    .then (sprints) ->
      sprintIds = sprints.map( (sprint) -> sprint.id ).join(',')
      jql = "project in (#{projectId()}) AND issuetype in standardIssueTypes() AND status in (Resolved, Closed) AND Sprint in (#{sprintIds}) AND updated >= -24h"
      requestUrl = "/rest/api/2/search?jql=#{jql}"

      new Promise (resolve, reject) ->
        getFromJira robot, requestUrl, (err, resp, body) ->
          try
            bodyObj = JSON.parse(body)
            issues = bodyObj.issues || []
            resolve issues
          catch error
            reject error

fetchFreeAgents = (robot) ->
  fetchUsers(robot)
    .then (users) ->
      fetchInProgressSubtasks(robot)
        .then (subtasks) ->
          freeAgents = users.filter (user) ->
            !subtasks.find (issue) ->
              if issue.fields.assignee?
                return issue.fields.assignee.key == user.key
              else
                return false
          return freeAgents

fetchAllReports = (robot) ->
  allFetchMethods = [
    fetchRecentlyClosedStories,
    fetchInProgressSubtasks,
    fetchFreeAgents,
  ]
  Promise.all(allFetchMethods.map((method) -> method(robot)))
#
# generate*Report methods all return a string with a specific report type
#
generateSprintsReport = (sprints) ->
  "Sprints: #{sprints.map((sprint) -> sprint.id).join(', ')}"

generateUsersReport = (users) ->
  "Users: #{users.map((user) -> user.name).join(', ')}"

generateInProgressReport = (inProgressIssues) ->
  # Example output:
  #
  # In Progress tasks:
  #   * @assigned - 3h remaining on ID - Title
  #   * @assigned - 16h remaining on ID - Title
  #      \-> Not updated since yesterday. http://link
  #   * *unassigned* - 30h remaining -
  sortedIssues = inProgressIssues.sort (leftIssue, rightIssue) ->
    leftAssignee = leftIssue.fields.assignee
    rightAssignee = rightIssue.fields.assignee
    if leftAssignee?
      if rightAssignee?
        # We have 2 actual users. Let's compare keys.
        if leftAssignee.key < rightAssignee.key
          return -1
        else if leftAssignee.key > rightAssignee.key
          return 1
        return 0
      else
        return 1
    else
      if rightAssignee?
        return -1
      return 0


  renderedList = sortedIssues.map (issue) ->
    # Useful computed data
    issueLink = "#{jiraUrl()}/browse/#{issue.key}"
    secondsLeft = issue.fields.progress.total - issue.fields.progress.progress
    updatedAgo = moment.duration(moment().diff(moment(issue.fields.updated)))

    if issue.fields.assignee?
      assigneeString = issue.fields.assignee.name
    else
      assigneeString = "unassigned"
    timeRemaining = "#{moment.duration(secondsLeft, 'seconds') .asHours()}h remaining"

    # Issue warnings
    hasntBeenUpdatedIn24hours = updatedAgo.asHours() > 24
    isUnassigned = !issue.fields.assignee?
    shouldBeResolved = secondsLeft <= 0

    # Bold any concerning fields
    if isUnassigned
      assigneeString = "*#{assigneeString}*"
    if secondsLeft <= 0
      timeRemaining = "*#{timeRemaining}*"

    # Main line rendering
    renderedIssue = "\t#{assigneeString}, #{timeRemaining} - #{issue.fields.summary} (#{issue.key})"

    # Show any warnings with the issue link
    if shouldBeResolved
      renderedIssue += "\n\t\t↳ Should this be marked as Completed? #{issueLink}"
    else if isUnassigned
      renderedIssue += "\n\t\t↳ Who's working on this? #{issueLink}"
    else if hasntBeenUpdatedIn24hours
      renderedIssue += "\n\t\t↳ This hasn't been updated since yesterday. #{issueLink}"

    return renderedIssue

  return "In progress tasks:\n#{renderedList.join('\n')}"

generateFreeAgentsReport = (users) ->
  return "Free agents:\n\t#{users.map((user) -> user.name).join(', ')}"

generateClosedStoriesReport = (stories) ->
  renderedStories = stories.map (issue) ->
    return "\t#{issue.key} #{issue.fields.summary}"
  return "Recently closed stories: \n#{renderedStories.join('\n')}"

generateAllReports = (fetchResults) ->
  generationFunctions = [
    generateClosedStoriesReport,
    generateInProgressReport,
    generateFreeAgentsReport,
  ]
  fetchResults.map (results, index) ->
    generationFunctions[index](results)


#
# respondWith is the boilerplate for our pattern of:
#   * Check environment variables
#   * fetch the data required for the report
#   * generate the report
#   * post the report
#
respondWith = (robot, res, fetchMethod, generateMethod) ->
  if !isConfiguredCorrectly(res)
    return

  fetchAndGenerate(robot, fetchMethod, generateMethod)
    .then (report) ->
      if Array.isArray(report)
        report.forEach (item) ->
          res.send item
      else
        res.send report

#
# Robot listening registry
#
module.exports = (robot) ->
  robot.on "jira:sprints", (res) ->
    respondWith robot, res, fetchSprints, generateSprintsReport
  robot.respond /show jira sprints/i, (res) ->
    respondWith robot, res, fetchSprints, generateSprintsReport

  robot.on "jira:users", (res) ->
    respondWith robot, res fetchUsers, generateUsersReport
  robot.respond /show jira users/i, (res) ->
    respondWith robot, res fetchUsers, generateUsersReport

  robot.on "jira:in-progress", (res) ->
    respondWith robot, res, fetchInProgressSubtasks, generateInProgressReport
  robot.respond /show jira in progress/i, (res) ->
    respondWith robot, res, fetchInProgressSubtasks, generateInProgressReport

  robot.on "jira:free-agents", (res) ->
    respondWith robot, res, fetchFreeAgents, generateFreeAgentsReport
  robot.respond /show jira free agents/i, (res) ->
    respondWith robot, res, fetchFreeAgents, generateFreeAgentsReport

  robot.on "jira:closed", (res) ->
    respondWith robot, res, fetchRecentlyClosedStories, generateClosedStoriesReport
  robot.respond /show jira closed stories/i, (res) ->
    respondWith robot, res, fetchRecentlyClosedStories, generateClosedStoriesReport

  robot.on "jira:report", (res) ->
    respondWith robot, res, fetchAllReports, generateAllReports
  robot.respond /show jira report/i, (res) ->
    respondWith robot, res, fetchAllReports, generateAllReports

  robot.respond /hi$/i, (msg) ->
    if !isConfiguredCorrectly(msg)
      return

    msg.send 'hi'

  robot.respond /emit (.*)/i, (res) ->
    event = res.match[1]
    robot.emit event, res
