chai   = require("chai")
chai.config.includeStack = true
assert = chai.assert
nock   = require("nock")
Helper = require("hubot-test-helper")

Path   = require("path")
pkg = require Path.join __dirname, "..", "package.json"
pkgVersion = pkg.version

room   = null
url    = null
helper = new Helper(Path.join(__dirname, "..", "src", "graph-me.coffee"))

describe "graph-me", () ->

  # say something to Hubot
  hubot = (message) ->
    room.messages = []
    room.user.say "otheruser", "hubot #{message}"
    room.messages.shift()

  # return Hubot's next response
  hubotResponse = () ->
    room.messages[0][1]

  # assert that Hubot's next response is the passed `expected` message
  assertHubotResponse = (expected) ->
    assert.deepEqual room.messages[0], ["hubot", "@otheruser #{expected}"]

  # skip past a line of Hubot's response
  skipHubotResponse = () ->
    room.messages.shift()

  beforeEach () ->
    url = "https://graphite.example.com"
    process.env["HUBOT_GRAPHITE_URL"] = url + "/"
    process.env["HUBOT_GRAPHITE_S3_BUCKET"] = "bucket"
    process.env["HUBOT_GRAPHITE_S3_ACCESS_KEY_ID"] = "access_key_id"
    process.env["HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY"] = "secret_access_key"
    room = helper.createRoom(httpd: false)

    # forbid all unspecified HTTP requests
    nock.disableNetConnect()

  afterEach (done) ->
    nock.cleanAll()
    setTimeout(done, 20)

  # fake image data used in tests
  image_data = () ->
    "This is image data"

  # -----------------------------------------------------

  describe "when asking for help", () ->

    it "responds to requests to `/graph` with an offer of help", () ->
      hubot "graph"
      assertHubotResponse "Type: `help graph` for usage info"

    it "responds to requests to `/graph me` with an offer of help", () ->
      hubot "graph me"
      assertHubotResponse "Type: `help graph` for usage info"

  describe "configuration checks", () ->

    it "fail if HUBOT_GRAPHITE_URL is not set", () ->
      delete process.env.HUBOT_GRAPHITE_URL
      hubot "graph whatever"
      assert.match hubotResponse(), /HUBOT_GRAPHITE_URL/

    it "fail if HUBOT_GRAPHITE_S3_BUCKET is not set", () ->
      delete process.env.HUBOT_GRAPHITE_S3_BUCKET
      hubot "graph whatever"
      assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_BUCKET/

    it "fail if HUBOT_GRAPHITE_S3_ACCESS_KEY_ID is not set", () ->
      delete process.env.HUBOT_GRAPHITE_S3_ACCESS_KEY_ID
      hubot "graph whatever"
      assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_ACCESS_KEY_ID/

    it "fail if HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY is not set", () ->
      delete process.env.HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY
      hubot "graph whatever"
      assert.match hubotResponse(), /HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY/

  describe "when handling /graph requests", () ->

    beforeEach () ->
      # stub requests to graphite
      nock("https://graphite.example.com").get("/render").query(true).reply(200, image_data())

      # stub requests to S3
      nock("https://bucket.s3.amazonaws.com")
        .filteringPath(/hubot-graphme\/.*/, "hubot-graphme")
        .put("/hubot-graphme", image_data())
        .reply(200, "OK")

    it "eliminates any trailing '/' characters from HUBOT_GRAPHITE_URL", (done) ->
      process.env["HUBOT_GRAPHITE_URL"] = url + "///"
      hubot "graph me vmpooler.running.debian-6-x386"
      assertHubotResponse "#{url}/render?target=vmpooler.running.debian-6-x386&format=png"
      setTimeout(done, 20)

    it "when given a basic target, responds with a target URL", (done) ->
      hubot "graph me vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&format=png"
      setTimeout(done, 20)

    it "when given a from time and a target, responds with a URL with from time", (done) ->
      hubot "graph me -1h vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1h&format=png"
      setTimeout(done, 20)

    it "converts -1m to -1min in from time", (done) ->
      hubot "graph me -1m vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-1min&format=png"
      setTimeout(done, 20)

    it "supports absolute from times like 'today'", (done) ->
      hubot "graph me today vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today&format=png"
      setTimeout(done, 20)

    it "supports absolute from times like '1/1/2014'", (done) ->
      hubot "graph me 1/1/2014 vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=1%2F1%2F2014&format=png"
      setTimeout(done, 20)

    it "supports absolute from times like 'now-5days'", (done) ->
      hubot "graph me now-5days vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=now-5days&format=png"
      setTimeout(done, 20)

    it "supports time ranges like '-6days..-1h'", (done) ->
      hubot "graph me -6days..-1h vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=-1h&format=png"
      setTimeout(done, 20)

    it "supports time ranges like 'today..-1h'", (done) ->
      hubot "graph me today..-1h vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=today&until=-1h&format=png"
      setTimeout(done, 20)

    it "supports time ranges like '-6days..today'", (done) ->
      hubot "graph me -6days..today vmpooler.running.*"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&from=-6days&until=today&format=png"
      setTimeout(done, 20)

    it "supports multiple targets", (done) ->
      hubot "graph me vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&format=png"
      setTimeout(done, 20)

    it "supports multiple targets with absolute start times", (done) ->
      hubot "graph me -6days vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&from=-6days&format=png"
      setTimeout(done, 20)

    it "supports multiple targets with a time range", (done) ->
      hubot "graph me -6days..-1h vmpooler.running.* + summarize(foo.bar.baz,\"1day\")"
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&from=-6days&until=-1h&format=png"
      setTimeout(done, 20)

    it "supports more than two targets, with a time range", (done) ->
      hubot "graph me -6days..-1h vmpooler.running.* + summarize(foo.bar.baz,\"1day\")  +  x.y.z   "
      assertHubotResponse "#{url}/render?target=vmpooler.running.*&target=summarize(foo.bar.baz%2C%221day%22)&target=x.y.z&from=-6days&until=-1h&format=png"
      setTimeout(done, 20)

  describe "when uploading images to S3", () ->

    afterEach () ->
      # reset this ENV variable, which is manipulated here
      delete process.env.HUBOT_GRAPHITE_S3_IMAGE_PATH

    it "stores uploaded images in hubot-graphme/ by default", (done) ->
      nock("https://graphite.example.com").get("/render").query(true).reply(200, image_data())
      expectation = nock("https://bucket.s3.amazonaws.com")
        .filteringPath(/hubot-graphme\/.*/, "hubot-graphme")
        .put("/hubot-graphme", image_data())
        .reply(200, "OK")

      hubot "graph me -1h vmpooler.running.*"
      setTimeout(expectation.done, 20)
      setTimeout(done, 20)

    it "allows overriding image storage folder", (done) ->
      nock("https://graphite.example.com").get("/render").query(true).reply(200, image_data())
      expectation = nock("https://bucket.s3.amazonaws.com")
        .filteringPath(/secret-path\/.*/, "secret-path")
        .put("/secret-path", image_data())
        .reply(200, "OK")

      process.env["HUBOT_GRAPHITE_S3_IMAGE_PATH"] = "secret-path"
      hubot "graph me -1h vmpooler.running.*"
      setTimeout(expectation.done, 20)
      setTimeout(done, 20)

    it "uploads an image snapshot to S3", (done) ->
      nock("https://graphite.example.com").get("/render").query(true).reply(200, image_data())
      expectation = nock("https://bucket.s3.amazonaws.com").filteringPath(/hubot-graphme\/.*/, "hubot-graphme")
        .put("/hubot-graphme", image_data())
        .reply(200, "OK")

      hubot "graph me -1h vmpooler.running.*"
      setTimeout(expectation.done, 20)
      setTimeout(done, 20)
