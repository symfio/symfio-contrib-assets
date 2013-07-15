# symfio-contrib-assets

> Compile and serve assets from public directory.

[![Build Status](https://travis-ci.org/symfio/symfio-contrib-assets.png?branch=master)](https://travis-ci.org/symfio/symfio-contrib-assets)
[![NPM version](https://badge.fury.io/js/symfio-contrib-assets.png)](http://badge.fury.io/js/symfio-contrib-assets)
[![Dependency Status](https://gemnasium.com/symfio/symfio-contrib-assets.png)](https://gemnasium.com/symfio/symfio-contrib-assets)
[![NPM version](https://badge.fury.io/js/symfio-contrib-assets.png)](http://badge.fury.io/js/symfio-contrib-assets)

## Usage

```coffee
symfio = require "symfio"

container = symfio "example", __dirname

container.inject require "symfio-contrib-express"
container.inject require "symfio-contrib-assets"
```

## Dependencies

* [contrib-express](https://github.com/symfio/symfio-contrib-express)

## Configuration

### `publicDirectory`

Directory with assets. Default value is `public`.

## Services

### `serve`

Assets serving helper. First argument is path to directory with assets.

### `servePublicDirectory`

Function used to serve public directory.
