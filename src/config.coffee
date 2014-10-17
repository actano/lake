path = require 'path'
fs = require 'fs'

try
  require 'coffee-script/register'

_config = undefined
_root = undefined

loadOldConfig = (root) ->
  p = path.join root, '.lake'
  if fs.existsSync p
    config = require path.join p, 'config'
    unless config.config.lakeOutput?
      config.config.lakeOutput = path.join p, 'build'
    return config

loadConfig = (root) ->
  p = path.join root, 'lake.config'
  try
    configurator = require p
  catch e

  return configurator unless configurator instanceof Function

  c =
    config:
      lakePath: root
      lakeOutput: path.join root, 'build', 'lake'
  configurator c
  return c


findConfig = ->
  currPath = process.cwd().split path.sep
  while currPath.length
    root = "/#{path.join currPath...}"
    _config = loadConfig root
    _config = loadOldConfig root unless _config?
    if _config
      _root = root
      return true

    currPath.pop()

  return false

module.exports =
  projectRoot: ->
    unless _root? || findConfig()
      return undefined

    return _root

  config: ->
    unless _config? || findConfig()
      return undefined

    return _config
