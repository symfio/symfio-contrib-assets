suite = require "symfio-suite"


describe "contrib-assets example", ->
  it = suite.example require "../example"

  check = (url, text) ->
    (request) ->
      request.get(url).then (res) ->
        res.should.have.status 200
        res.text.should.equal text

  describe "GET /stylus-example.css", ->
    it "should respond with compiled stylus",
      check "/stylus-example.css", """
      .selector {\n  color: #f00;\n}\n
      """

  describe "GET /stylus-nib-example.css", ->
    it "should respond with compiled stylus with imported nib",
      check "/stylus-nib-example.css", """
      .selector {\n  border: 1px solid #f00;\n}\n
      """

  describe "GET /stylus-responsive-example.css", ->
    it "should respond with compiled stylus with imported responsive",
      check "/stylus-responsive-example.css", """
      .selector {
        width: 100px;
      }
      @media (max-width: 767px) {
        .selector {
          width: 50px;
        }
      }\n
      """

  describe "GET /jade-example.html", ->
    it "should respond with compiled jade",
      check "/jade-example.html", """
      <!DOCTYPE html><head><title>Test</title></head>
      """

  describe "GET /coffeescript-example.js", ->
    # see https://github.com/chaijs/chai-http/issues/4
    it.skip "should respond with compiled coffeescript",
      check "/coffeescript-example.js", """
      (function() {
        alert(\"Hello World!\");

      }).call(this);\n
      """

  describe "GET /robots.txt", ->
    it "should respond with static file",
      check "/robots.txt", """
      User-agent: *\nDisallow: /\n
      """
