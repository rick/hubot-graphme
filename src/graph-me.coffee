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
#   hubot graph me metrics.something.* - show a graph for a graphite query using a target
#
# Author:
#   Rick Bradley (github.com/rick, rick@rickbradley.com)

module.exports = (robot) ->
  robot.respond /env/, (msg) ->
    msg.reply graphite_url()

  robot.respond /graph( me)?\s+/, (msg) ->
    if process.env["HUBOT_GRAPHITE_URL"]
      msg.reply "graphing."
    else
      msg.reply "HUBOT_GRAPHITE_URL is unset."
