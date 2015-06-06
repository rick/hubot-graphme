Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
url    = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->

  hubot = (message) ->
    room.user.say "rick", "hubot #{message}"

  hubotResponse = () ->
    room.messages[1][1]

  assertHubotResponse = (expected) ->
    assert.deepEqual ['hubot', "@rick #{expected}"], room.messages[1]

  beforeEach () ->
    url = "https://graphite.example.com"
    process.env["HUBOT_GRAPHITE_URL"] = url + "/"
    room = helper.createRoom()

  # -----------------------------------------------------

  it 'fails if HUBOT_GRAPHITE_URL is not set', () ->
    delete process.env.HUBOT_GRAPHITE_URL
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_URL/

  it 'eliminates any trailing "/" characters from HUBOT_GRAPHITE_URL', () ->
    process.env["HUBOT_GRAPHITE_URL"] = url + '/'
    hubot "graph me vmpooler.running.debian-6-x386"
    assertHubotResponse "https://graphite.example.com/render?target=vmpooler.running.debian-6-x386"


  it 'responds to requests to `/graph` with an offer of help', () ->
    hubot "graph"
    assertHubotResponse "Type: `help graph` for usage info"

  it 'responds to requests to `/graph me` with an offer of help', () ->
    hubot "graph me"
    assertHubotResponse "Type: `help graph` for usage info"

  it 'when given a basic target, responds with a target URL', () ->
    hubot 'graph me vmpooler.running.*'
    assertHubotResponse "#{url}/render?target=vmpooler.running.*"

  it 'when given a duration and a target, responds with a URL with duration', () ->
    hubot 'graph me -1h vmpooler.running.*'
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1h"

  it 'rejects invalid durations', () ->
    hubot "graph me -1b vmpooler.running.*"
    assert.match hubotResponse(), /duration/

    hubot "graph me -1monday vmpooler.running.*"
    assert.match hubotResponse(), /duration/

  it 'converts -1m to -1min', () ->
    hubot "graph me -1m vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1min"
