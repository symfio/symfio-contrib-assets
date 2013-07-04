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


module.exports = (container) ->
  container.unless "publicDirectory", (applicationDirectory) ->
    path.join applicationDirectory, "public"

  container.set "serve", (logger, app, express) ->
    (directory) ->
      logger.debug "serve assets", directory: directory

      logger.debug "use express middleware", name: "stylus"
      app.use stylus.middleware(
        src: directory
        compile: compilerFactory
      )

      logger.debug "use express middleware", name: "jade"
      app.use jade directory

      logger.debug "use express middleware", name: "coffeescript"
      app.use coffeescript directory

      logger.debug "use express middleware", name: "static"
      app.use express.static directory


  container.inject (serve, publicDirectory) ->
    serve publicDirectory
