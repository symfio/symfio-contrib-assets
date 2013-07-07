coffeescript = require "connect-coffee-script"
responsive = require "stylus-responsive"
stylus = require "stylus"
nodefn = require "when/node/function"
jade = require "jade-static"
path = require "path"
nib = require "nib"
fs = require "fs"
w = require "when"


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


  container.inject (serve, publicDirectory, logger) ->
    checkDirectory = (stats) ->
      unless stats.isDirectory()
        logger.warn "`publicDirectory' isn't directory", path: publicDirectory
        return w.reject()

    createDirectory = (err) ->
      logger.debug "create public directory", path: publicDirectory
      nodefn.call fs.mkdir, publicDirectory if err.errno is 34

    nodefn.call(fs.stat, publicDirectory)
    .then(checkDirectory, createDirectory)
    .then ->
      serve publicDirectory
