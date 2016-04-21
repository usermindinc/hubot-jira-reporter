Helper = require('hubot-test-helper')
expect = require('chai').expect

# helper loads a specific script if it's a file
helper = new Helper('./../src/jira-reporter.coffee')

describe 'jira-reporter', ->
  room = null

  beforeEach ->
    # Set up the room before running the test
    room = helper.createRoom()

  afterEach ->
    # Tear it down after the test to free up the listener.
    room.destroy()

  context 'user says hi to hubot', ->
    beforeEach ->
      room.user.say 'alice', 'hubot hi'

    it 'should reply hi to user', ->
      expect(room.messages).to.eql [
        ['alice', 'hubot hi']
        ['hubot', 'hi']
      ]
