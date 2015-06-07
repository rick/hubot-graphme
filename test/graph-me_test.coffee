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

  assertHubotResponse = (expected, offset = 1) ->
    assert.deepEqual room.messages[offset], ['hubot', "@rick #{expected}"]

  beforeEach () ->
    url = "https://graphite.example.com"
    process.env["HUBOT_GRAPHITE_URL"] = url + "/"
    process.env["HUBOT_GRAPHITE_S3_BUCKET"] = "bucketname"
    process.env["HUBOT_GRAPHITE_S3_ACCESS_KEY_ID"] = "1234567890"
    process.env["HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY"] = "987543210"
    room = helper.createRoom()

  # -----------------------------------------------------

  it 'fails if HUBOT_GRAPHITE_URL is not set', () ->
    delete process.env.HUBOT_GRAPHITE_URL
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_URL/

  it 'fails if HUBOT_GRAPHITE_S3_BUCKET is not set', () ->
    delete process.env.HUBOT_GRAPHITE_S3_BUCKET
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_BUCKET/

  it 'fails if HUBOT_GRAPHITE_S3_ACCESS_KEY_ID is not set', () ->
    delete process.env.HUBOT_GRAPHITE_S3_ACCESS_KEY_ID
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_ACCESS_KEY_ID/

  it 'fails if HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY is not set', () ->
    delete process.env.HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY
    hubot "graph whatever"
    assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY/

  it 'eliminates any trailing "/" characters from HUBOT_GRAPHITE_URL', () ->
    process.env["HUBOT_GRAPHITE_URL"] = url + '/'
    hubot "graph me vmpooler.running.debian-6-x386"
    assertHubotResponse "https://graphite.example.com/render?target=vmpooler.running.debian-6-x386&format=png"

  it 'responds to requests to `/graph` with an offer of help', () ->
    hubot "graph"
    assertHubotResponse "Type: `help graph` for usage info"

  it 'responds to requests to `/graph me` with an offer of help', () ->
    hubot "graph me"
    assertHubotResponse "Type: `help graph` for usage info"

  it 'when given a basic target, responds with a target URL', () ->
    hubot 'graph me vmpooler.running.*'
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&format=png"

  it 'when given a from time and a target, responds with a URL with from time', () ->
    hubot 'graph me -1h vmpooler.running.*'
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1h&format=png"

  it 'converts -1m to -1min in from time', () ->
    hubot "graph me -1m vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1min&format=png"

  it 'supports absolute from times', () ->
    hubot "graph me today vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today&format=png"

    hubot "graph me 1/1/2014 vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=1%2F1%2F2014&format=png"

    hubot "graph me now-5days vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=now-5days&format=png"

  it 'supports time ranges', () ->
    hubot "graph me -6days..-1h vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=-1h&format=png"

    hubot "graph me today..-1h vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today&until=-1h&format=png"

    hubot "graph me -6days..today vmpooler.running.*"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=today&format=png"

  it 'supports multiple targets', () ->
    hubot "graph me vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&format=png"

    hubot "graph me -6days vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&from=-6days&format=png"

    hubot "graph me -6days..-1h vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&from=-6days&until=-1h&format=png"

    hubot "graph me -6days..-1h vmpooler.running.* + summarize(foo.bar.baz,\"1day\")  +  x.y.z   "
    assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&target=x.y.z&from=-6days&until=-1h&format=png"
