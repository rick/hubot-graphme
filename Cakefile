# Cakefile

{exec} = require "child_process"

task "test", "run tests", ->
  exec "NODE_ENV=test ./node_modules/.bin/mocha --opts test/mocha.opts", (err, output) ->
    console.log output
    if err
      console.log err
      process.exit 1
