path = require 'path'
fs = require 'fs'

try
  require 'coffee-script/register'

_config = undefined
_root = undefined

loadOldConfig = (root) ->
  p = path.join root, '.lake'
  if fs.existsSync p
    return require path.join p, 'config'

loadConfig = (root) ->
  p = path.join root, 'lake.config'
  try
    return require p
  catch e

findConfig = ->
  currPath = process.cwd().split path.sep
  while currPath.length
    root = "/#{path.join currPath...}"
    _config = loadConfig(root) || loadOldConfig(root)
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

if require.main is module
  console.log module.exports.projectRoot()