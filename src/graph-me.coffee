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
util    = require "util"
knox    = require "knox"
http    = require "http"

module.exports = (robot) ->

  notConfigured = () ->
    result = []
    result.push "HUBOT_GRAPHITE_URL" unless process.env['HUBOT_GRAPHITE_URL']
    result.push "HUBOT_GRAPHITE_S3_BUCKET" unless process.env['HUBOT_GRAPHITE_S3_BUCKET']
    result.push "HUBOT_GRAPHITE_S3_ACCESS_KEY_ID" unless process.env['HUBOT_GRAPHITE_S3_ACCESS_KEY_ID']
    result.push "HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY" unless process.env['HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY']
    result

  isConfigured = () ->
    notConfigured().length == 0

  config = {
      bucket          : process.env['HUBOT_GRAPHITE_S3_BUCKET'],
      accessKeyId     : process.env['HUBOT_GRAPHITE_S3_ACCESS_KEY_ID'],
      secretAccessKey : process.env['HUBOT_GRAPHITE_S3_SECRET_ACCESS_KEY'],
      region          : "us-east-1" # TODO make this configurable
    }

  AWSCredentials = {
      accessKeyId     : config["accessKeyId"]
      secretAccessKey : config["secretAccessKey"]
      region          : config["region"]
    }

  # Fetch an image from provided URL, upload it to S3, returning the resulting URL
  fetchAndUpload = (msg, url) ->
    client = knox.createClient {
      key    : AWSCredentials["accessKeyId"]
      secret : AWSCredentials["secretAccessKey"],
      bucket : config["bucket"]
    }

    # pick a random filename
    filename = "hubot-graphme/" + crypto.randomBytes(20).toString('hex') + ".png"

    http.get('http://github.com/rick.png', (res) ->
      msg.reply "Inside #{util.inspect(res)}"

      headers =
        'Content-Length': res.headers['content-length']
        'Content-Type': res.headers['content-type']

      client.putStream res, filename, headers, (err, res) ->
        if !err
          msg.reply "https://s3.amazonaws.com/#{bucket}/#{filename}"
        else
          msg.reply "Error: #{err}"
    ).on 'error', (e) ->
      msg.reply "Got an error: #{e}"

  timePattern = '(?:[-_:\/+a-zA-Z0-9]+)'

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
      url = process.env["HUBOT_GRAPHITE_URL"].replace(/\/+$/, '') # drop trailing '/'s
      from    = msg.match[1]
      through = msg.match[2]
      targets  = msg.match[3]

      result = []

      if targets
        targets.split(/\s+\+\s+/).map (target) ->
          result.push "target=#{encodeURIComponent(target)}"

        if from?
          from += "in" if from.match /\d+m$/ # -1m -> -1min
          result.push "from=#{encodeURIComponent(from)}"

          if through?
            through += "in" if through.match /\d+m$/ # -1m -> -1min
            result.push "until=#{encodeURIComponent(through)}"

        result.push "format=png"
        graphiteURL = "#{url}/render?#{result.join("&")}"

        msg.reply graphiteURL

        fetchAndUpload(msg, graphiteURL)
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "Configuration variables are not set: #{notConfigured().join(", ")}."
