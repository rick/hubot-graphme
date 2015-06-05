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
  robot.respond /^graph( me)?\s+/, (msg) ->
    msg.reply "graphing."
