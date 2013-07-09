callbacks = require "when/callbacks"
nodefn = require "when/node/function"
crypto = require "crypto"
send = require "send"
glob = require "glob"
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


  matchCacheFile = (url, cacheDirectory, ext) ->
    hash = crypto.createHash("sha1").update(url).digest("hex")
    path.join cacheDirectory, "#{hash}.#{ext}"


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

  container.set "assetsServers", (app, assetsMiddleware) ->
    servers: []

    match: (req) ->
      return unless req.method in ["GET", "HEAD"]

      for server in @servers
        if server.matchRegex.test req.url
          return server

    register: (dir, sourceExt, destinationExt, directoryIndex, compiler) ->
      app.use assetsMiddleware @ if @servers.length == 0

      matchRegex = if directoryIndex
        new RegExp "(\\/|\\.#{destinationExt})$"
      else
        new RegExp "\\.#{destinationExt}$"

      server =
        directory: dir
        sourceExt: sourceExt
        destinationExt: destinationExt
        directoryIndex: directoryIndex
        compiler: compiler
        matchRegex: matchRegex
        globPattern: "#{dir}/**/*.#{sourceExt}"
        extRegex: new RegExp "#{destinationExt}$"

      @servers.push server

  container.set "assetsMiddleware", (cacheDirectory) ->
    (assetsServers) ->
      (req, res, next) ->
        s = assetsServers.match req
        return next() unless s

        if s.directoryIndex and req.url[-1..] is "/"
          url = "#{req.url}index.#{s.destinationExt}"
        else
          url = req.url

        file = path.join s.directory, url.replace s.extRegex, s.sourceExt
        cacheFile = matchCacheFile url, cacheDirectory, s.destinationExt

        onFulfilled = (data) ->
          hash = path.basename cacheFile, path.extname cacheFile
          res.set "X-Assets-Hash", hash
          send(req, cacheFile).pipe res

        onRejected = (err) ->
          res.send 500

        recompile(file, cacheFile, s.compiler)
        .then onFulfilled, onRejected

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

  container.set "serveJade", (assetsServers, compileJade, logger) ->
    (directory) ->
      logger.debug "serve", type: "jade", path: directory
      assetsServers.register directory, "jade", "html", true, compileJade

  container.set "coffee", ->
    require "coffee-script"

  container.set "compileCoffee", (coffee) ->
    (file) ->
      nodefn.call(fs.readFile, file).then (data) ->
        coffee.compile data.toString()

  container.set "serveCoffee", (assetsServers, compileCoffee, logger) ->
    (directory) ->
      logger.debug "serve", type: "coffee", path: directory
      assetsServers.register directory, "coffee", "js", false, compileCoffee

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

  container.set "serveStylus", (assetsServers, compileStylus, logger) ->
    (directory) ->
      logger.debug "serve", type: "stylus", path: directory
      assetsServers.register directory, "styl", "css", false, compileStylus

  container.set "serve", (serveStatic, serveJade, serveCoffee, serveStylus) ->
    (directory) ->
      serveStatic directory
      serveJade directory
      serveCoffee directory
      serveStylus directory

  container.set "precompileAssets", (assetsServers, cacheDirectory, logger) ->
    ->
      w.map assetsServers.servers, (server) ->
        nodefn.call(glob, server.globPattern)
        .then (files) ->
          w.map files, (file) ->
            url = file.replace(server.directory, "")
            cacheFile = matchCacheFile url, cacheDirectory,
              server.destinationExt
            logger.debug "precompile", file: file, cacheFile: cacheFile, url: url
            recompile file, cacheFile, server.compiler

  container.inject (serve, publicDirectory) ->
    serve publicDirectory
