suite = require "symfio-suite"


describe "contrib-assets()", ->
  it = suite.plugin (container, stub) ->
    container.inject ["suite/container"], require ".."
    container.require require
    container.require "when/node/function"
    container.require "path"
    container.set "applicationDirectory", "/"
    container.set "publicDirectory", "/"
    container.set "fs", (sandbox) ->
      stat: sandbox.stub()
      mkdir: sandbox.stub()

    stub.setFunction "serveStatic"
    stub.setFunction "serveJade"
    stub.setFunction "serveCoffee"
    stub.setFunction "serveStylus"
    stub.setFunction "serve"
    stub.setPromisedFunction "assets/createDirectory"

  describe "container.set assets/createDirectory", ->
    it "should reject if publicDirectory isn't directory", (setted, fs) ->
      fs.stat.yields null, isDirectory: -> false
      factory = setted "assets/createDirectory"
      factory().then (createDirectory) ->
        createDirectory("/").should.be.rejected

    it "should create directory", (setted, fs) ->
      fs.stat.yields errno: 34
      fs.mkdir.yields()
      factory = setted "assets/createDirectory"
      factory().then (createDirectory) ->
        createDirectory "/"
      .then ->
        fs.mkdir.should.be.calledOnce
        fs.mkdir.should.be.calledWith "/"

  describe "container.unless publicDirectory", ->
    it "should define", (unlessed) ->
      factory = unlessed "publicDirectory"
      factory().should.eventually.equal "/public"

  describe "container.set serve", ->
    it "should register four middlewares", (setted) ->
      factory = setted "serve"
      factory().then (serve) ->
        serve "/"
        for dependency in factory.args
          dependency.should.be.calledOnce
          dependency.should.be.calledWith "/"

  describe "container.set servePublicDirectory", ->
    it "should serve publicDirectory", (setted) ->
      factory = setted "servePublicDirectory"
      factory().then (servePublicDirectory) ->
        servePublicDirectory()
        factory.dependencies.serve.should.be.calledOnce
        factory.dependencies.serve.should.be.calledWith "/"
