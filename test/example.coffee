chai = require "chai"
w = require "when"


describe "contrib-assets example", ->
  chai.use require "chai-as-promised"
  chai.use require "chai-http"
  chai.should()

  container = require "../example"

  before (callback) ->
    container.set "autoload", false
    container.set "env", "test"
    container.load().should.notify callback

  check = (url, text) ->
    container.get("app").then (app) ->
      deferred = w.defer()
      chai.request(app).get(url).res deferred.resolve
      deferred.promise
    .then (res) ->
      res.should.have.status 200
      res.text.should.equal text

  describe "GET /stylus-example.css", ->
    it "should respond with compiled stylus", (callback) ->
      text = ".selector {\n  color: #f00;\n}\n"
      check("/stylus-example.css", text).should.notify callback

  describe "GET /stylus-nib-example.css", ->
    it "should respond with compiled stylus with imported nib", (callback) ->
      text = ".selector {\n  border: 1px solid #f00;\n}\n"
      check("/stylus-nib-example.css", text).should.notify callback

  describe "GET /stylus-responsive-example.css", ->
    it "should respond with compiled stylus with imported responsive",
      (callback) ->
        text = """
        .selector {
          width: 100px;
        }
        @media (max-width: 767px) {
          .selector {
            width: 50px;
          }
        }\n
        """
        check("/stylus-responsive-example.css", text).should.notify callback

  describe "GET /jade-example.html", ->
    it "should respond with compiled jade", (callback) ->
      text = "<!DOCTYPE html><head><title>Test</title></head>"
      check("/jade-example.html", text).should.notify callback

  describe "GET /coffeescript-example.js", ->
    # see https://github.com/chaijs/chai-http/issues/4
    it.skip "should respond with compiled coffeescript", (callback) ->
      text = """
      (function() {
        alert(\"Hello World!\");

      }).call(this);\n
      """
      check("/coffeescript-example.js", text).should.notify callback

  describe "GET /robots.txt", ->
    it "should respond with static file", (callback) ->
      text = "User-agent: *\nDisallow: /\n"
      check("/robots.txt", text).should.notify callback
