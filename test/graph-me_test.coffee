Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->
  beforeEach () ->
    room = helper.createRoom()

  hubot = (message) ->
    room.user.say "rick", "hubot #{message}"

  assertHubotResponse = (expected) ->
    assert.deepEqual ['hubot', "@rick #{expected}"], room.messages[1]

  it 'responds to requests to `/graph `', () ->
    hubot "graph whatever"
    assertHubotResponse "graphing."

  it 'responds to requests to `/graph me`', () ->
    hubot "graph me whatever"
    assertHubotResponse "graphing."
