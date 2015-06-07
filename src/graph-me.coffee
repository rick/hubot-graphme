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
#   hubot graph me vmpooler.running.*                                    - show a graph for a graphite query using a target
#   hubot graph me -1h vmpooler.running.*                                - show a graphite graph with a target and a from time
#   hubot graph me -6h..-1h vmpooler.running.*                           - show a graphite graph with a target and a time range
#   hubot graph me -6h..-1h foo.bar.baz + summarize(bar.baz.foo, "1day") - show a graphite graph with multiple targets
#
# Author:
#   Rick Bradley (rick@rickbradley.com, github.com/rick)

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

    if process.env["HUBOT_GRAPHITE_URL"]
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

        msg.reply "#{url}/render?#{result.join("&")}"
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
