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
  robot.respond /env/, (msg) ->
    msg.reply graphite_url()

  robot.respond /graph(?:\s+me)?(?:\s+(.*))?/, (msg) ->
    if process.env["HUBOT_GRAPHITE_URL"]
      url = process.env["HUBOT_GRAPHITE_URL"]
      spec = msg.match[1]

      if spec
        msg.reply "#{url}/render?target=#{spec}"
      else
        msg.reply "Type: `help graph` for usage info"
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
