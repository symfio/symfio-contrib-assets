plugin = require ".."
suite = require "symfio-suite"
fs = require "fs"


describe "contrib-assets()", ->
  it = suite.plugin [
    (container) ->
      container.set "applicationDirectory", __dirname

      container.set "app", (sandbox) ->
        use: sandbox.spy()

      container.set "express", (sandbox) ->
        static: sandbox.spy()

      container.inject (sandbox) ->
        sandbox.stub fs, "stat"
        fs.stat.yields errno: 34

        sandbox.stub fs, "mkdir"
        fs.mkdir.yields null

    plugin
  ]

  describe "container.unless publicDirectory", ->
    it "should define", (publicDirectory) ->
      publicDirectory.should.equal "#{__dirname}/public"

  describe "container.set serve", ->
    it "should register four middlewares", (app, serve) ->
      app.use.reset()
      serve __dirname
      app.use.callCount.should.equal 4

  it "should reject if publicDirectory isn't directory", (container) ->
    fs.stat.yields null, isDirectory: -> false
    container.inject(plugin).should.be.rejected

  it "should create directory", (publicDirectory) ->
    fs.mkdir.should.be.calledOnce
    fs.mkdir.should.be.calledWith publicDirectory

  it "should serve publicDirectory", (container, publicDirectory) ->
    container.set "publicDirectory", publicDirectory
    container.set "serve", (sandbox) ->
      sandbox.spy()

    container.inject (sandbox) ->
      sandbox.stub container, "set"
      container.inject plugin
    .then ->
      container.get "serve"
    .then (serve) ->
      serve.should.be.calledOnce
      serve.should.be.calledWith publicDirectory
