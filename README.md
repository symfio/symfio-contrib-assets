# symfio-contrib-assets

> Compile and serve assets from public directory.

[![Build Status](http://teamcity.rithis.com/httpAuth/app/rest/builds/buildType:id:bt10,branch:master/statusIcon?guest=1)](http://teamcity.rithis.com/viewType.html?buildTypeId=bt10&guest=1)
[![Dependency Status](https://gemnasium.com/symfio/symfio-contrib-assets.png)](https://gemnasium.com/symfio/symfio-contrib-assets)

## Usage

```coffee
symfio = require "symfio"

container = symfio "example", __dirname

container.use require "symfio-contrib-express"
container.use require "symfio-contrib-assets"

container.load()
```

## Required plugins

* [contrib-express](https://github.com/symfio/symfio-contrib-express)

## Provides

* __serve__ — Assets serving helper. First argument is path to directory with
  assets.

## Can be configured

* __public directory__ — Directory with assets. Default value is `public`.
