Helper = require('hubot-test-helper')
expect = require('chai').expect
nock = require('nock')

# helper loads a specific script if it's a file
helper = new Helper('./../src/jira-reporter.coffee')

# Environment variables used during testing
environment =
  jiraUrl: 'http://example.atlassian.net'
  user: 'johnDoe'
  password: 'password'
  projectId: 'ABC'

describe 'jira-reporter', ->
  room = null

  beforeEach ->
    # Set up the room before running the test
    room = helper.createRoom()
    do nock.disableNetConnect
    nock("https://usermind.atlassian.net")
      .get("/rest/greenhopper/1.0/integration/teamcalendars/sprint/list?jql=")
      .reply 200, { "nope": "nope" }

  afterEach ->
    # Tear it down after the test to free up the listener.
    room.destroy()

  context 'with poorly configured environment variables', ->
    context 'missing all config', ->
      beforeEach ->
        room.user.say 'alice', 'hubot hi'

      it 'will complain about everything', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot hi'],
          ['hubot',
            'Missing HUBOT_JIRA_URL environment variable\n' +
            'Missing HUBOT_JIRA_USERNAME environment variable\n' +
            'Missing HUBOT_JIRA_PASSWORD environment variable\n' +
            'Missing HUBOT_JIRA_PROJECT_ID environment variable'
          ]
        ]

    context 'correctly configured', ->
      beforeEach ->
        process.env.HUBOT_JIRA_URL = environment.jiraUrl
        process.env.HUBOT_JIRA_USERNAME = environment.user
        process.env.HUBOT_JIRA_PASSWORD = environment.password
        process.env.HUBOT_JIRA_PROJECT_ID = environment.projectId
        room.user.say 'alice', 'hubot hi'

      it 'will respond with a greeting', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot hi'],
          ['hubot', 'hi']
        ]

  # context 'user says hi to hubot', ->
  #   beforeEach ->
  #     room.user.say 'alice', 'hubot hi'
  #
  #   it 'should reply hi to user', ->
  #     expect(room.messages).to.eql [
  #       ['alice', 'hubot hi']
  #       ['hubot', 'hi']
  #     ]

  #
  # context 'user says "show jira sprints" to hubot' ->
  #   beforeEach ->
  #     room.user.say 'alice', 'hubot show jira sprints'
  #
  #   it 'should reply with sprint ids', ->
  #     expect(room.messages).to.eql [
  #       ['alice', 'hubot show jira sprints']
  #       ['hubot', 'no']
  #     ]
