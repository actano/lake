path = require 'path'
# TODO: refactor this, don't use component.json anymore, use Manifest.coffee
pkg = require './component.json'
server = require './server'

describe_feature = require '../feature'

module.exports = describe_feature(
    name: pkg.name
    description: pkg.description
    mountPoint: "/#{pkg.name}"
    server: server

    widget:
        htmlPath: path.join __dirname, 'views', 'widget.jade'
        cssPath: path.join __dirname, 'build', "#{pkg.name}.css"
        jsPath: path.join __dirname, 'build', "#{pkg.name}.js"

    page:
        htmlPath: path.join __dirname, 'views', 'demo.jade'
)

