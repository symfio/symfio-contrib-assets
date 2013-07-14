symfio = require "symfio"


module.exports = container = symfio "example", __dirname

module.exports.promise = container.injectAll([
  require "symfio-contrib-winston"
  require "symfio-contrib-express"
  require ".."
]).then ->
  container.get "servePublicDirectory"
.then (servePublicDirectory) ->
  servePublicDirectory()

if require.main is module
  module.exports.promise.then ->
    container.get "startExpressServer"
  .then (startExpressServer) ->
    startExpressServer()
