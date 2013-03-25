symfio = require "symfio"
plugin = require "../lib/assets"
suite = require "symfio-suite"


describe "contrib-assets plugin", ->
  wrapper = suite.sandbox symfio, ->
    express = static: @sandbox.stub()
    app = use: @sandbox.stub()

    @container.set "public directory", __dirname
    @container.set "express", express
    @container.set "app", app

  it "should output message", wrapper ->
    plugin @container, ->

    @expect(@logger.info).to.have.been.calledOnce
    @expect(@logger.info.lastCall.args[0]).to.equal "loading plugin"
    @expect(@logger.info.lastCall.args[1]).to.equal "contrib-assets"
