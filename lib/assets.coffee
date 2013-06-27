coffeescript = require "connect-coffee-script"
responsive = require "stylus-responsive"
stylus = require "stylus"
jade = require "jade-static"
path = require "path"
nib = require "nib"


compilerFactory = (str, path) ->
  compiler = stylus str

  compiler.set "filename", path
  compiler.set "compress", false

  compiler.use nib()
  compiler.use responsive


module.exports = (container, applicationDirectory, publicDirectory) ->
  unless publicDirectory
    container.set "publicDirectory", path.join applicationDirectory, "public"

  container.set "serve", (app, express) ->
    (directory) ->
      app.use stylus.middleware
        src: directory
        compile: compilerFactory

      app.use jade directory
      app.use coffeescript directory
      app.use express.static directory

  container.call (serve, publicDirectory) ->
    serve publicDirectory
