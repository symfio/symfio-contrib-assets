callbacks = require "when/callbacks"
nodefn = require "when/node/function"
crypto = require "crypto"
send = require "send"
path = require "path"
fs = require "fs"
w = require "when"


module.exports = (container) ->
  createDirectory = (dir) ->
    onFulfilled = (stats) ->
      throw new Error "`#{dir}' isn't directory" unless stats.isDirectory()

    onRejected = (err) ->
      throw err unless err.errno is 34
      nodefn.call fs.mkdir, dir

    nodefn.call(fs.stat, dir)
    .then onFulfilled, onRejected


  compareStat = (file, cacheFile) ->
    stat = nodefn.lift fs.stat
    w.join(stat(file), stat(cacheFile))
    .spread (fileStats, cacheFileStats) ->
      fileStats.mtime > cacheFileStats.mtime


  recompileNeeded = (file, cacheFile) ->
    callbacks.call(fs.exists, cacheFile)
    .then (exists) ->
      return true unless exists
      compareStat file, cacheFile


  compile = (file, cacheFile, compiler) ->
    compiler(file)
    .then (data) ->
      nodefn.call fs.writeFile, cacheFile, data


  recompile = (file, cacheFile, compiler) ->
    recompileNeeded(file, cacheFile)
    .then (needed) ->
      compile file, cacheFile, compiler if needed


  container.unless "publicDirectory", (applicationDirectory) ->
    publicDirectory = path.join applicationDirectory, "public"
    createDirectory(publicDirectory).then ->
      publicDirectory

  container.unless "cacheDirectory", (applicationDirectory) ->
    cacheDirectory = path.join applicationDirectory, "cache"
    createDirectory(cacheDirectory).then ->
      cacheDirectory

  container.set "registerCompiler", (app, cacheDirectory) ->
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
        hash = crypto.createHash("sha1").update(url).digest("hex")
        cacheFile = path.join cacheDirectory, "#{hash}.#{destinationExt}"

        onFulfilled = (data) ->
          send(req, cacheFile).pipe res

        onRejected = (err) ->
          res.send 500

        recompile(file, cacheFile, compiler).then onFulfilled, onRejected

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
    serve publicDirectory
