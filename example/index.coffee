symfio = require "symfio"

module.exports = container = symfio "example", __dirname

container.use require "symfio-contrib-express"
container.use require ".."

container.load() if require.main is module
