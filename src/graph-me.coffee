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
#   hubot graph me vmpooler.running.*     - show a graph for a graphite query using a target
#   hubot graph me -1h vmpooler.running.* - show a graphite graph with a target and a from time
#
# Author:
#   Rick Bradley (github.com/rick, rick@rickbradley.com)

module.exports = (robot) ->

  encodeParams = (data) ->
    Object.keys(data).map((key) ->
      [
        key
        data[key]
      ].map(encodeURIComponent).join '='
    ).join '&'

  robot.respond ///
    graph(?:\s+me)?                       # graph me

    (?:
      (?:\s+
        (                                 # \1 - capture
          (?:                             # relative from time
            -\d+                          # -5
            (?:s|m|min|mon|h|d|w|y)\w*    # s, sec, m, min, mon, h, hours, d, days, ...
          )
          |
          (?:                             # absolute from time
            [-_:\/+a-zA-Z0-9]+            # "today", "1/1/2014", "now-5days", "04:00_20110501", etc.
          )
        )
      )?                                  # from times are optional

      (?:\s+                              # graphite target string
        (.*)                              # \2 - capture
      )
    )?                                    # time + target is also optional
  ///, (msg) ->

    if process.env["HUBOT_GRAPHITE_URL"]
      url = process.env["HUBOT_GRAPHITE_URL"].replace(/\/+$/, '') # drop trailing '/'s
      from   = msg.match[1]
      target = msg.match[2]

      if target
        params = { target: target }
        if from?
          if from.match /^-/              # relative from time
            from += "in" if from.match /-\d+m$/ # -1m -> -1min
          params["from"] = from

        msg.reply "#{url}/render?#{encodeParams(params)}"
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
