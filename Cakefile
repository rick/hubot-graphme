# Cakefile

{exec} = require "child_process"

REPORTER = "min"

task "test", "run tests", ->
  exec "NODE_ENV=test ./node_modules/.bin/mocha --full-trace", (err, output) ->
    console.log output
    if err
      console.log err
      process.exit 1
