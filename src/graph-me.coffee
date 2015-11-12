# Description:
#   Render graphite graphs
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GRAPHITE_URL                  - Location where graphite web interface can be found (e.g., "https://graphite.domain.com")
#   HUBOT_GRAPHITE_S3_BUCKET            - Amazon S3 bucket where graph snapshots will be stored
#   HUBOT_GRAPHITE_S3_ACCESS_KEY_ID     - Amazon S3 access key ID for snapshot storage
#   HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY - Amazon S3 secret access key for snapshot storage
#   HUBOT_GRAPHITE_S3_REGION            - Amazon S3 region (default: "us-east-1")
#   HUBOT_GRAPHITE_S3_IMAGE_PATH        - Subdirectory in which to store S3 snapshots (default: "hubot-graphme")
#
# Commands:
#   hubot graph me vmpooler.running.*                                    - show a graph for a graphite query using a target
#   hubot graph me -1h vmpooler.running.*                                - show a graphite graph with a target and a from time
#   hubot graph me -6h..-1h vmpooler.running.*                           - show a graphite graph with a target and a time range
#   hubot graph me -6h..-1h foo.bar.baz + summarize(bar.baz.foo,"1day")  - show a graphite graph with multiple targets
#
# Author:
#   Rick Bradley (rick@rickbradley.com, github.com/rick)

crypto  = require "crypto"
knox    = require "knox"
request = require "request"

module.exports = (robot) ->

  notConfigured = () ->
    result = []
    result.push "HUBOT_GRAPHITE_URL" unless process.env["HUBOT_GRAPHITE_URL"]
    result.push "HUBOT_GRAPHITE_S3_BUCKET" unless process.env["HUBOT_GRAPHITE_S3_BUCKET"]
    result.push "HUBOT_GRAPHITE_S3_ACCESS_KEY_ID" unless process.env["HUBOT_GRAPHITE_S3_ACCESS_KEY_ID"]
    result.push "HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY" unless process.env["HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY"]
    result

  isConfigured = () ->
    process.env["HUBOT_GRAPHITE_URL"]

  buildQuery = (from, through, targets) ->
    return false unless targets

    result = []
    targets.split(/\s+\+\s+/).map (target) ->
      result.push "target=#{encodeURIComponent(target)}"

    if from?
      from += "in" if from.match /\d+m$/ # -1m -> -1min
      result.push "from=#{encodeURIComponent(from)}"

      if through?
        through += "in" if through.match /\d+m$/ # -1m -> -1min
        result.push "until=#{encodeURIComponent(through)}"

    result.push "lineMode=connected"
    result.push "yMin=0"
    result.push "width=1280"
    result.push "height=400"
    result.push "format=png"
    result

  uploadFolder = () ->
    return "hubot-graphme" unless process.env["HUBOT_GRAPHITE_S3_IMAGE_PATH"]
    process.env["HUBOT_GRAPHITE_S3_IMAGE_PATH"].replace(/\/+$/, "")

  config = {
      bucket          : process.env["HUBOT_GRAPHITE_S3_BUCKET"],
      accessKeyId     : process.env["HUBOT_GRAPHITE_S3_ACCESS_KEY_ID"],
      secretAccessKey : process.env["HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY"],
      imagePath       : uploadFolder()
      region          : process.env["HUBOT_GRAPHITE_S3_REGION"] || "us-east-1"
    }

  AWSCredentials = {
      accessKeyId     : config["accessKeyId"]
      secretAccessKey : config["secretAccessKey"]
      region          : config["region"]
    }

  # pick a random filename
  randomFilename = () ->
    "#{crypto.randomBytes(20).toString("hex")}.png"

  timestamp = () ->
    (new Date).toISOString().replace(/[^\d]/g, '')[..7] # e.g., 20150923

  uploadPath = (filename) ->
    "#{uploadFolder()}/#{timestamp()}/#{filename}"

  imgURL = (filename) ->
    "https://#{config["bucket"]}.s3.amazonaws.com/#{uploadPath(filename)}"

  # Fetch an image from provided URL, upload it to S3, returning the resulting URL
  fetchAndUpload = (msg, url) ->
    msg.reply url
    request url, { encoding: null }, (err, response, body) ->
      if typeof body isnt "undefined" # hacky
        uploadToS3(msg, body, body.length, response.headers["content-type"])
      else
        msg.reply "Graphite request error: #{err}, response: #{response}"

  uploadClient = () ->
    knox.createClient {
      key    : AWSCredentials["accessKeyId"],
      secret : AWSCredentials["secretAccessKey"],
      bucket : config["bucket"]
    }

  buildUploadRequest = (filename, length, content_type) ->
    headers = {
      "Content-Length" : length,
      "Content-Type"   : content_type,
      "x-amz-acl"      : "public-read",
      "encoding"       : null
    }
    uploadClient().put(uploadPath(filename), headers)

  uploadToS3 = (msg, content, length, content_type) ->
    filename = randomFilename()
    req = buildUploadRequest(filename, length, content_type)
    req.on "response", (res) ->
      if (200 == res.statusCode)
        msg.reply imgURL(filename)
        return true
      else
        msg.reply "Image snapshot upload error: \##{res.statusCode} - #{res.statusMessage}"
        return false
    req.on "error", (err) ->
      msg.reply "Image snapshot upload error: \##{err.statusCode} - #{err.statusMessage}"
      return false
    req.end(content)

  #
  #  build robot grammar regex
  #

  timePattern = "(?:[-_:\/+a-zA-Z0-9]+)"

  robot.respond ///
    graph(?:\s+me)?                       # graph me

    (?:                                   # optional time range
      (?:\s+
        (#{timePattern})                  # \1 - capture (from)
        (?:
        \.\.\.?                              # from..through range
          (#{timePattern})                # \2 - capture (until)
        )?
      )?

      (?:\s+                              # graphite targets
        (                                 # \3 - capture
          \S+                             # a graphite target
          (?:\s+\+\s+                     # " + "
            \S+                           # more graphite targets
          )*
        )
      )
    )?                                    # time + target is also optional
  ///, (msg) ->

    if isConfigured()
      url     = process.env["HUBOT_GRAPHITE_URL"].replace(/\/+$/, "") # drop trailing "/"s
      from    = msg.match[1]
      through = msg.match[2]
      targets = msg.match[3]

      if query = buildQuery(from, through, targets)
        if process.env["HUBOT_GRAPHITE_S3_ACCESS_KEY_ID"]
          fetchAndUpload(msg, "#{url}/render?#{query.join("&")}")
        else
            msg.send "#{url}/render?#{query.join("&")}"
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.send "Configuration variables are not set: #{notConfigured().join(", ")}."
