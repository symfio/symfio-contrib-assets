coffeescript = require "connect-coffee-script"
responsive = require "stylus-responsive"
stylus = require "stylus"
nodefn = require "when/node/function"
jade = require "jade-static"
path = require "path"
nib = require "nib"
fs = require "fs"


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
      nodefn.call(fs.stat, directory)
      .then (stats) ->
        unless stats.isDirectory()
          logger.warn "serve directory isn't directory", path: directory
          return w.reject()
      , (err) ->
        nodefn.call fs.mkdir, directory if err.errno is 34

      .then ->
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
