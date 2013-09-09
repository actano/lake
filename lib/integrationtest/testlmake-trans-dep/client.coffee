dom = require 'dom'
bindTemplate = require "bind-jade"
transModule = require './trans_module'

class TestlmakeTransDep
    constructor: (parentElement) ->
        parentElement ?= ".content"
        parent = dom(parentElement)
        template = bindTemplate require './views/dummy-partial'
        parent.append template(transModule)

module.exports = TestlmakeTransDep


