dom = require 'dom'
bindTemplate = require "bind-jade"
TestDep = require 'testlmake-dep'

text = "Hello World"
div = dom("<span>#{text}</span>")


class Testlmake
    constructor: (parentElement) ->
        parentElement ?= ".content"
        parent = dom(parentElement)
        parent.append(div)

        locals =
            list:
                ['Hello', 'World', 'and', 'goodbye']

        liTemplate = bindTemplate require './views/list-entry-partial'
        list = liTemplate locals
        parent.append list

        modifyList = dom("<div class='testlmake modify'><ul class='content'><li>foo</li></li></ul></div>")
        parent.append modifyList

        testdep = new TestDep()

module.exports = Testlmake


