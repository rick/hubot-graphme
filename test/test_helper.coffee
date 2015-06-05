global.assert = require("chai").assert
require("chai").config.includeStack = true
process.env.NODE_ENV = 'test'
process.env.HUBOT_DEPLOY_APPS_JSON = require("path").join(__dirname, "test_apps.json")
