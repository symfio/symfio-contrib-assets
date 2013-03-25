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

  compiler.import "nib"
  compiler.import "responsive"


module.exports = (container, callback) ->
  applicationDirectory = container.get "application directory"
  publicDirectory = path.join applicationDirectory, "public"

  publicDirectory = container.get "public directory", publicDirectory
  express = container.get "express"
  logger = container.get "logger"
  app = container.get "app"

  logger.info "loading plugin", "contrib-assets"

  serve = (directory) ->
    app.use stylus.middleware (
      src: directory
      compile: compilerFactory
    )

    app.use jade directory
    app.use coffeescript directory
    app.use express.static directory

  container.set "assets serve helper", serve
  serve publicDirectory

  callback()
