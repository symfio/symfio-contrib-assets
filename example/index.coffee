symfio = require "symfio"
async = require "async"
path = require "path"
fs = require "fs"

module.exports = container = symfio "example", __dirname
container.set "public directory", path.join __dirname, "public"

loader = container.get "loader"
loader.use require "symfio-contrib-express"
loader.use require "../lib/assets"

unloader = container.get "unloader"

unloader.register (callback) ->
  publicDirectory = container.get "public directory"

  fs.readdir publicDirectory, (err, files) ->
    return callback() if err

    worker = (file, callback) ->
      return callback() unless /\.(css|html|js)$/.test file

      file = path.join publicDirectory, file
      fs.unlink file, callback

    async.forEach files, worker, callback

loader.load() if require.main is module
