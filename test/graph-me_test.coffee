Path   = require("path")
Helper = require('hubot-test-helper')

pkg = require Path.join __dirname, "..", 'package.json'
pkgVersion = pkg.version

room   = null
url    = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->

  hubot = (message) ->
    room.messages = []
    room.user.say "rick", "hubot #{message}"

  hubotResponse = () ->
    room.messages[1][1]

  assertHubotResponse = (expected) ->
    assert.deepEqual room.messages[1], ['hubot', "@rick #{expected}"]

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

  it 'when given a from time and a target, responds with a URL with from time', () ->
    hubot 'graph me -1h vmpooler.running.*'
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1h"

  it 'converts -1m to -1min in from time', () ->
    hubot "graph me -1m vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1min"

  it 'supports absolute from times', () ->
    hubot "graph me today vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today"

    hubot "graph me 1/1/2014 vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=1%2F1%2F2014"

    hubot "graph me now-5days vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=now-5days"

  it 'supports time ranges', () ->
    hubot "graph me -6days..-1h vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=-1h"

    hubot "graph me today..-1h vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today&until=-1h"

    hubot "graph me -6days..today vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=today"
