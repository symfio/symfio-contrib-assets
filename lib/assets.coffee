callbacks = require "when/callbacks"
nodefn = require "when/node/function"
path = require "path"
fs = require "fs"
w = require "when"


module.exports = (container) ->
  container.unless "publicDirectory", (applicationDirectory) ->
    path.join applicationDirectory, "public"

  container.set "registerCompiler", (app) ->
    (directory, sourceExt, destinationExt, directoryIndex, compiler) ->
      if directoryIndex
        matchRegex = new RegExp "(\\/|\\.#{destinationExt})$"
      else
        matchRegex = new RegExp "\\.#{destinationExt}$"

      extRegex = new RegExp "#{destinationExt}$"

      app.use (req, res, next) ->
        return next() unless req.method is "GET"
        return next() unless matchRegex.test req.url

        if directoryIndex and req.url[-1..] is "/"
          url = "#{req.url}index.#{destinationExt}"
        else
          url = req.url

        file = path.join directory, url.replace extRegex, sourceExt

        respondData = (data) ->
          res.send data

        respondError = (err) ->
          console.log err
          res.send 500

        callbacks.call(fs.exists, file)
        .then (exists) ->
          return next() unless exists
          compiler file
        .then respondData, respondError

  container.set "serveStatic", (app, express, logger) ->
    (directory) ->
      logger.debug "serve", type: "static", path: directory
      app.use express.static directory

  container.set "jade", ->
    require "jade"

  container.set "compileJade", (jade) ->
    (file, locals) ->
      nodefn.call(fs.readFile, file).then (data) ->
        fn = jade.compile data.toString(), filename: file
        fn locals

  container.set "serveJade", (registerCompiler, compileJade, logger) ->
    (directory) ->
      logger.debug "serve", type: "jade", path: directory
      registerCompiler directory, "jade", "html", true, compileJade

  container.set "coffee", ->
    require "coffee-script"

  container.set "compileCoffee", (coffee) ->
    (file) ->
      nodefn.call(fs.readFile, file).then (data) ->
        coffee.compile data.toString()

  container.set "serveCoffee", (registerCompiler, compileCoffee, logger) ->
    (directory) ->
      logger.debug "serve", type: "coffee", path: directory
      registerCompiler directory, "coffee", "js", false, compileCoffee

  container.set "stylus", ->
    require "stylus"

  container.set "nib", ->
    require "nib"

  container.set "stylusResponsive", ->
    require "stylus-responsive"

  container.set "compileStylus", (stylus, nib, stylusResponsive) ->
    (file, paths) ->
      nodefn.call(fs.readFile, file).then (data) ->
        compiler = stylus data.toString()
        compiler.set "filename", file
        compiler.use nib()
        compiler.use stylusResponsive
        nodefn.call compiler.render.bind compiler

  container.set "serveStylus", (registerCompiler, compileStylus, logger) ->
    (directory) ->
      logger.debug "serve", type: "stylus", path: directory
      registerCompiler directory, "styl", "css", false, compileStylus

  container.set "serve", (serveStatic, serveJade, serveCoffee, serveStylus) ->
    (directory) ->
      serveStatic directory
      serveJade directory
      serveCoffee directory
      serveStylus directory


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
