Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->

  hubot = (message) ->
    room.user.say "rick", "hubot #{message}"

  hubotResponse = () ->
    room.messages[1][1]

  assertHubotResponse = (expected) ->
    assert.deepEqual ['hubot', "@rick #{expected}"], room.messages[1]

  beforeEach () ->
    process.env["HUBOT_GRAPHITE_URL"] = "https://graphite.example.com/"
    room = helper.createRoom()

  # -----------------------------------------------------

  it 'fails if HUBOT_GRAPHITE_URL is not set', () ->
    delete process.env.HUBOT_GRAPHITE_URL
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_URL/

  it 'responds to requests to `/graph` with an offer of help', () ->
    hubot "graph"
    assertHubotResponse "Type: `help graph` for usage info"

  it 'responds to requests to `/graph me` with an offer of help', () ->
    hubot "graph me"
    assertHubotResponse "Type: `help graph` for usage info"
