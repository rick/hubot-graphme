path = require 'path'
Robot = require 'hubot/src/robot'
messages = require 'hubot/src/message'

describe 'graph-me', ->
  robot = null
  adapter = null
  user = null

  beforeEach ->
    robot = new Robot(null, 'mock-adapter', false, 'Hubot')
    robot.adapter.on 'connected', ->
      (require '../src/graph-me')(robot)
      user = robot.brain.userForId('1', name: 'jasmine', room: '#jasmine')
      adapter = robot.adapter
    robot.run()

  afterEach ->
    robot.shutdown()

  say = (msg) ->
    adapter.receive new messages.TextMessage(user, msg)

  expectHubotToSay = (msg, done) ->
    adapter.on 'send', (envelope, strings) ->
      (expect strings[0]).toMatch msg
      done()


  it 'responds to requests to `/graph me`', (done) ->
    expectHubotToSay 'graphing.'
    say 'hubot graph me whatever'
    done()
