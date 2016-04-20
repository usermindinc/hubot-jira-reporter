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
# moment     = require 'moment'
# schedule   = require 'node-schedule'
# Promise    = require 'promise'
# _          = require 'underscore'

jiraUrl = process.env.HUBOT_JIRA_URL
projectId = process.env.HUBOT_JIRA_PROJECT_ID
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

  if !jiraUrl?
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

fetchSprints = (robot) ->
  sprintsJql = "project = #{projectId} and Sprint not in closedSprints()"
  requestUrl = "#{jiraUrl}/rest/greenhopper/1.0/integration/teamcalendars/sprint/list?jql=#{sprintsJql}"

  return new Promise (resolve, reject) ->

    robot.http(requestUrl)
      .header('Authorization', "Basic #{authPayload()}")
      .get() (err, resp, body) ->
        try
          bodyObj = JSON.parse(body)
          sprints = bodyObj.sprints || []
          resolve sprints
        catch error
          reject error


#
# Robot listening registry
#
module.exports = (robot) ->

  robot.respond /show jira sprints/i, (res) ->
    fetchSprints(robot)
      .then (sprints) ->
        res.send "Sprints: #{sprints.map((sprint) -> sprint.id).join(', ')}"

  robot.respond /check/i, (res) ->
    if !isConfiguredCorrectly(res)
      return


    # Find the currently open Sprint


    data =
      jql: "project in (#{projectId}) AND status = \"In Progress\" AND Sprint in (80)"
      fields: 'key'
    requestUrl = "#{jiraUrl}/rest/api/2/search?jql=#{data.jql}&fields=#{data.fields}"

    robot.http(requestUrl)
      .header('Authorization', "Basic #{authPayload()}")
      .get() (err, resp, body)->
        bodyObj = JSON.parse(body)
        howMany = bodyObj.total
        res.send "Found #{howMany} issues: #{bodyObj.issues.length}"

        res.send bodyObj.issues.map( (issue) -> issue.key ).join(', ')
