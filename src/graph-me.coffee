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
#   hubot graph me vmpooler.running.*          - show a graph for a graphite query using a target
#   hubot graph me -1h vmpooler.running.*      - show a graphite graph with a target and a from time
#   hubot graph me -6h..-1h vmpooler.running.* - show a graphite graph with a target and a time range
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

      (?:\s+                              # graphite target string
        (.*)                              # \3 - capture
      )
    )?                                    # time + target is also optional
  ///, (msg) ->

    if process.env["HUBOT_GRAPHITE_URL"]
      url = process.env["HUBOT_GRAPHITE_URL"].replace(/\/+$/, '') # drop trailing '/'s
      from    = msg.match[1]
      through = msg.match[2]
      target  = msg.match[3]

      if target
        params = { target: target }

        if from?
          from += "in" if from.match /\d+m$/ # -1m -> -1min
          params["from"] = from

          if through?
            through += "in" if through.match /\d+m$/ # -1m -> -1min
            params["until"] = through

        msg.reply "#{url}/render?#{encodeParams(params)}"
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
