suite = require "symfio-suite"
fs = require "fs"


describe "contrib-assets()", ->
  it = suite.plugin (container, containerStub) ->
    require("..") containerStub
    
    container.set "app", (sandbox) ->
      app = sandbox.spy()
      app.use = sandbox.spy()
      app

    container.set "express", (sandbox) ->
      express = sandbox.spy()
      express.static = sandbox.spy()
      express

    container.set "serve", (sandbox) ->
      sandbox.spy()

    container.inject (sandbox) ->
      sandbox.stub fs, "stat"
      sandbox.stub fs, "mkdir"

  describe "container.unless publicDirectory", ->
    it "should define", (containerStub) ->
      factory = containerStub.unless.get "publicDirectory"
      factory("/").should.equal "/public"

  describe "container.set serve", ->
    it "should register four middlewares",
      (containerStub, logger, app, express) ->
        factory = containerStub.set.get "serve"
        serve = factory logger, app, express
        serve "/"
        app.use.callCount.should.equal 4
        express.static.should.calledWith "/"

  it "should reject if publicDirectory isn't directory",
    (containerStub, serve, logger) ->
      fs.stat.yields null, isDirectory: -> false
      factory = containerStub.inject.get 0
      factory(serve, "/", logger).should.be.rejected

  it "should create directory", (containerStub, serve, logger) ->
    fs.stat.yields errno: 34
    fs.mkdir.yields()
    factory = containerStub.inject.get 0
    factory(serve, "/", logger).then ->
      fs.mkdir.should.be.calledOnce
      fs.mkdir.should.be.calledWith "/"

  it "should serve publicDirectory", (containerStub, serve, logger) ->
    fs.stat.yields null, isDirectory: -> true
    factory = containerStub.inject.get 0
    factory(serve, "/", logger).then ->
      serve.should.be.calledOnce
      serve.should.be.calledWith "/"
