# Description:
#   Render graphite graphs
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot graph me summarize(vmpooler.running.*,"1h") - show a graph for a graphite query using a target
#
# Author:
#   Rick Bradley (github.com/rick, rick@rickbradley.com)

module.exports = (robot) ->

  durationPattern = /(-\d+(?:s|m|min|mon|h|d|w|y))/

  encodeParams = (data) ->
    Object.keys(data).map((key) ->
      [
        key
        data[key]
      ].map(encodeURIComponent).join '='
    ).join '&'

  robot.respond /env/, (msg) ->
    msg.reply graphite_url()

  robot.respond /graph(?:\s+me)?(?:\s+(-\d+\w+))?(?:\s+(.*))?/, (msg) ->
    if process.env["HUBOT_GRAPHITE_URL"]
      url = process.env["HUBOT_GRAPHITE_URL"].replace(/\/+$/, "")
      from   = msg.match[1]
      target = msg.match[2]

      if target
        params = { target: target }

        if from?
          if from.match durationPattern
            from += "in" if from.match /-\d+m$/ # -1m -> -1min
            params["from"] = from.replace(/(-\d+m)$/, )
          else
            msg.reply "could not understand from/duration (#{from})"

        msg.reply "#{url}/render?#{encodeParams(params)}"

      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
