module.exports = (container) ->
  container.require require
  container.require "when/node/function"
  container.require "stylusResponsive", "stylus-responsive"
  container.require "when/callbacks"
  container.require "coffeeScript", "coffee-script"
  container.require "stylus"
  container.require "crypto"
  container.require "jade"
  container.require "send"
  container.require "glob"
  container.require "path"
  container.require "nib"
  container.require "fs"


  container.set "assets/createDirectory",
    ["when/node/function", "fs"],
    (nodefn, fs) ->
      (dir) ->
        onFulfilled = (stats) ->
          throw new Error "`#{dir}' isn't directory" unless stats.isDirectory()

        onRejected = (err) ->
          throw err unless err.errno is 34
          nodefn.call fs.mkdir, dir

        nodefn.call(fs.stat, dir)
        .then onFulfilled, onRejected


  container.set "assets/computeCacheId", (crypto) ->
    (url) ->
      crypto.createHash("sha1").update(url).digest("hex")


  container.set "assets/compareStat",
    ["when/node/function", "fs", "w"],
    (nodefn, fs, w) ->
      (file, cacheFile) ->
        stat = nodefn.lift fs.stat
        w.join(stat(file), stat(cacheFile))
        .spread (fileStats, cacheFileStats) ->
          fileStats.mtime > cacheFileStats.mtime


  container.set "assets/recompileNeeded",
    ["when/callbacks", "fs", "assets/compareStat"],
    (callbacks, fs, compareStat) ->
      (file, cacheFile) ->
        callbacks.call(fs.exists, cacheFile)
        .then (exists) ->
          return true unless exists
          compareStat file, cacheFile


  container.set "assets/compile",
    ["when/node/function", "fs"],
    (nodefn, fs) ->
      (file, cacheFile, compiler) ->
        compiler(file)
        .then (data) ->
          nodefn.call fs.writeFile, cacheFile, data


  container.set "assets/recompile",
    ["assets/recompileNeeded", "assets/compile"],
    (recompileNeeded, compile) ->
      (file, cacheFile, compiler) ->
        recompileNeeded(file, cacheFile)
        .then (needed) ->
          if needed
            compile(file, cacheFile, compiler).then ->
              true
          else
            false


  container.unless "publicDirectory",
    ["path", "applicationDirectory", "assets/createDirectory"],
    (path, applicationDirectory, createDirectory) ->
      publicDirectory = path.join applicationDirectory, "public"
      createDirectory(publicDirectory).then ->
        publicDirectory


  container.unless "cacheDirectory",
    ["path", "applicationDirectory", "assets/createDirectory"],
    (path, applicationDirectory, createDirectory) ->
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


  container.set "assetsMiddleware",
    ["cacheDirectory", "assets/computeCacheId", "assets/recompile", "path",
    "send"],
    (cacheDirectory, computeCacheId, recompile, path, send) ->
      (assetsServers) ->
        (req, res, next) ->
          s = assetsServers.match req
          return next() unless s

          if s.directoryIndex and req.url[-1..] is "/"
            url = "#{req.url}index.#{s.destinationExt}"
          else
            url = req.url

          file = path.join s.directory, url.replace s.extRegex, s.sourceExt
          cacheId = computeCacheId url
          cacheFile = path.join cacheDirectory, "#{cacheId}.#{s.destinationExt}"

          onFulfilled = (recompiled) ->
            res.set "X-Assets-Cache", if recompiled
              "id=#{cacheId}; recompiled"
            else
              "id=#{cacheId}"
            send(req, cacheFile).pipe res

          onRejected = (err) ->
            res.send 500

          recompile(file, cacheFile, s.compiler)
          .then onFulfilled, onRejected


  container.set "serveStatic", (app, express, logger) ->
    (directory) ->
      logger.debug "serve", type: "static", path: directory
      app.use express.static directory


  container.set "compileJade",
    ["when/node/function", "jade", "fs"],
    (nodefn, jade, fs) ->
      (file, locals) ->
        nodefn.call(fs.readFile, file).then (data) ->
          fn = jade.compile data.toString(), filename: file
          fn locals


  container.set "serveJade", (assetsServers, compileJade, logger) ->
    (directory) ->
      logger.debug "serve", type: "jade", path: directory
      assetsServers.register directory, "jade", "html", true, compileJade


  container.set "compileCoffee",
    ["when/node/function", "coffeeScript", "fs"],
    (nodefn, coffeeScript, fs) ->
      (file) ->
        nodefn.call(fs.readFile, file).then (data) ->
          coffeeScript.compile data.toString()


  container.set "serveCoffee", (assetsServers, compileCoffee, logger) ->
    (directory) ->
      logger.debug "serve", type: "coffee", path: directory
      assetsServers.register directory, "coffee", "js", false, compileCoffee


  container.set "compileStylus",
    ["when/node/function", "stylus", "nib", "stylusResponsive", "fs"],
    (nodefn, stylus, nib, stylusResponsive, fs) ->
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


  container.set "precompileAssets",
    ["assetsServers", "cacheDirectory", "logger", "assets/computeCacheId",
    "assets/recompile", "path", "when/node/function", "w", "glob"],
    (assetsServers, cacheDirectory, logger, computeCacheId, recompile, path,
    nodefn, w, glob) ->
      ->
        w.map assetsServers.servers, (server) ->
          nodefn.call(glob, server.globPattern)
          .then (files) ->
            w.map files, (file) ->
              url = file.replace(server.directory, "")
              cacheId = computeCacheId url
              cacheFile = path.join cacheDirectory,
                "#{cacheId}.#{s.destinationExt}"
              logger.debug "precompile", file: file, cacheId: cacheId, url: url
              recompile file, cacheFile, server.compiler


  container.set "servePublicDirectory", (serve, publicDirectory) ->
    ->
      serve publicDirectory
