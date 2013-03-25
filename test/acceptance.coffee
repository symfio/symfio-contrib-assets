suite = require "symfio-suite"


describe "contrib-assets example", ->
  wrapper = suite.http require "../example"

  describe "GET /stylus-example.css", ->
    it "should respond with compiled stylus", wrapper (callback) ->
      text = ".selector {\n  color: #f00;\n}\n"

      test = @http.get "/stylus-example.css"
      test.res (res) =>
        @expect(res).to.have.status 200
        @expect(res.text).to.equal text
        callback()

  describe "GET /stylus-nib-example.css", ->
    it "should respond with compiled stylus with imported nib",
      wrapper (callback) ->
        text = ".selector {\n  border: 1px solid #f00;\n}\n"

        test = @http.get "/stylus-nib-example.css"
        test.res (res) =>
          @expect(res).to.have.status 200
          @expect(res.text).to.equal text
          callback()

  describe "GET /stylus-responsive-example.css", ->
    it "should respond with compiled stylus with imported responsive",
      wrapper (callback) ->
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

        test = @http.get "/stylus-responsive-example.css"
        test.res (res) =>
          @expect(res).to.have.status 200
          @expect(res.text).to.equal text
          callback()

  describe "GET /jade-example.html", ->
    it "should respond with compiled jade", wrapper (callback) ->
      text = "<!DOCTYPE html><head><title>Test</title></head>"

      test = @http.get "/jade-example.html"
      test.res (res) =>
        @expect(res).to.have.status 200
        @expect(res.text).to.equal text
        callback()

  describe "GET /coffeescript-example.js", ->
    # see https://github.com/chaijs/chai-http/issues/4
    it.skip "should respond with compiled coffeescript", wrapper (callback) ->
      text = "(function() {\n  alert(\"Hello World!\");\n\n}).call(this);\n"

      test = @http.get "/coffeescript-example.js"
      test.res (res) =>
        @expect(res).to.have.status 200
        @expect(res.text).to.equal text
        callback()

  describe "GET /robots.txt", ->
    it "should respond with static file", wrapper (callback) ->
      text = "User-agent: *\nDisallow: /\n"

      test = @http.get "/robots.txt"
      test.res (res) =>
        @expect(res).to.have.status 200
        @expect(res.text).to.equal text
        callback()
