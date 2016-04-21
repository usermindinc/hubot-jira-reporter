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
  userGroup: 'brown-coats'

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

  context 'missing environment variables: ', ->
    # afterEach ->
    #   process.env.HUBOT_JIRA_URL = undefined
    #   process.env.HUBOT_JIRA_USERNAME = undefined
    #   process.env.HUBOT_JIRA_PASSWORD = undefined
    #   process.env.HUBOT_JIRA_PROJECT_ID = undefined
    #   process.env.HUBOT_JIRA_REPORT_USER_GROUP = undefined

    afterEach ->
      process.env = {}
    context 'All', ->
      beforeEach ->
        room.user.say 'alice', 'hubot show jira free agents'

      it 'will complain about everything', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot',
            'Missing HUBOT_JIRA_URL environment variable\n' +
            'Missing HUBOT_JIRA_USERNAME environment variable\n' +
            'Missing HUBOT_JIRA_PASSWORD environment variable\n' +
            'Missing HUBOT_JIRA_PROJECT_ID environment variable'
          ]
        ]

    context 'All except HUBOT_JIRA_URL', ->
      beforeEach ->
        process.env =
          HUBOT_JIRA_URL: environment.jiraUrl
        room.user.say 'alice', 'hubot show jira free agents'
      afterEach ->
        process.env = {}

      it 'will complain about everything except HUBOT_JIRA_URL', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot',
            'Missing HUBOT_JIRA_USERNAME environment variable\n' +
            'Missing HUBOT_JIRA_PASSWORD environment variable\n' +
            'Missing HUBOT_JIRA_PROJECT_ID environment variable'
          ]
        ]

    context 'HUBOT_JIRA_URL', ->
      beforeEach ->
        process.env =
          HUBOT_JIRA_USERNAME: environment.user
          HUBOT_JIRA_PASSWORD: environment.password
          HUBOT_JIRA_PROJECT_ID: environment.projectId
        room.user.say 'alice', 'hubot show jira free agents'
      afterEach ->
        process.env = {}

      it 'will complain about missing HUBOT_JIRA_URL', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot', 'Missing HUBOT_JIRA_URL environment variable']
        ]

    context 'HUBOT_JIRA_USERNAME', ->
      beforeEach ->
        process.env =
          HUBOT_JIRA_URL: environment.jiraUrl
          HUBOT_JIRA_PASSWORD: environment.password
          HUBOT_JIRA_PROJECT_ID: environment.projectId
        room.user.say 'alice', 'hubot show jira free agents'
      afterEach ->
        process.env = {}

      it 'will complain about missing HUBOT_JIRA_USERNAME', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot', 'Missing HUBOT_JIRA_USERNAME environment variable']
        ]

    context 'HUBOT_JIRA_PASSWORD', ->
      beforeEach ->
        process.env =
          HUBOT_JIRA_URL: environment.jiraUrl
          HUBOT_JIRA_USERNAME: environment.user
          HUBOT_JIRA_PROJECT_ID: environment.projectId
        room.user.say 'alice', 'hubot show jira free agents'
      afterEach ->
        process.env = {}

      it 'will complain about missing HUBOT_JIRA_PASSWORD', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot', 'Missing HUBOT_JIRA_PASSWORD environment variable']
        ]

    context 'HUBOT_JIRA_PROJECT_ID', ->
      beforeEach ->
        process.env =
          HUBOT_JIRA_URL: environment.jiraUrl
          HUBOT_JIRA_USERNAME: environment.user
          HUBOT_JIRA_PASSWORD: environment.password
        room.user.say 'alice', 'hubot show jira free agents'
      afterEach ->
        process.env = {}

      it 'will complain about missing HUBOT_JIRA_PROJECT_ID', ->
        expect(room.messages).to.eql [
          ['alice', 'hubot show jira free agents'],
          ['hubot', 'Missing HUBOT_JIRA_PROJECT_ID environment variable']
        ]

  context 'with only required environment variables', ->
    beforeEach ->
      process.env.HUBOT_JIRA_URL = environment.jiraUrl
      process.env.HUBOT_JIRA_USERNAME = environment.user
      process.env.HUBOT_JIRA_PASSWORD = environment.password
      process.env.HUBOT_JIRA_PROJECT_ID = environment.projectId
      room.user.say 'alice', 'hubot hi'
    afterEach ->
      process.env = {}

    it 'will respond with a greeting', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot hi'],
        ['hubot', 'hi']
      ]

  context 'with environment variables set including group', ->
    beforeEach ->
      process.env.HUBOT_JIRA_URL = environment.jiraUrl
      process.env.HUBOT_JIRA_USERNAME = environment.user
      process.env.HUBOT_JIRA_PASSWORD = environment.password
      process.env.HUBOT_JIRA_PROJECT_ID = environment.projectId
      process.env.HUBOT_JIRA_REPORT_USER_GROUP = environment.userGroup
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
