nodefn = require "when/node/function"
symfio = require "symfio"
fs = require "fs.extra"


module.exports = container = symfio "example", __dirname

module.exports.promise = container.injectAll([
  require "symfio-contrib-winston"
  require "symfio-contrib-express"

  ->
    nodefn.call(fs.remove, "#{__dirname}/cache").then ->
      container.inject require ".."
]).then ->
  container.get "servePublicDirectory"
.then (servePublicDirectory) ->
  servePublicDirectory()

if require.main is module
  module.exports.promise.then ->
    container.get "startExpressServer"
  .then (startExpressServer) ->
    startExpressServer()
