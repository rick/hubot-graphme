Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->
  beforeEach () ->
    room = helper.createRoom()

  it 'responds to requests to `/graph `', () ->
    room.user.say 'atmos', 'hubot graph whatever'
    assert.deepEqual ['hubot', "@atmos graphing."], room.messages[1]

  it 'responds to requests to `/graph me`', () ->
    room.user.say 'atmos', 'hubot graph me whatever'
    assert.deepEqual ['hubot', "@atmos graphing."], room.messages[1]
