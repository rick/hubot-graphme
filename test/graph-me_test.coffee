Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->
  beforeEach () ->
    room = helper.createRoom()

  say = (room, message) ->
    room.user.say 'rick', message

  assertResponse = (room, expected) ->
    assert.deepEqual ['hubot', "@rick #{expected}"], room.messages[1]

  it 'responds to requests to `/graph `', () ->
    say room, "hubot graph whatever"
    assertResponse room, "graphing."

  it 'responds to requests to `/graph me`', () ->
    say room, "hubot graph me whatever"
    assertResponse room, "graphing."
