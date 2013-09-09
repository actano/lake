phantom = require 'phantom'
config = require '../../config'
{expect} = require 'chai'

###
    1. on Mac OS X phantom doesn't work properly, this test doesn't work
    2. to pass this test (on linux), you need a server
    run `coffee server` (webapp should be stopped)
    or add this feature to the lib/webbapp, don't forget to do a global before `lmake install`
###

# @see client.coffee
describe 'root html page', ->

    # TODO: make a real test
    it.skip "should return a html page with a friendly 'Hello World' message", (done) ->
        # it "should return a html page with a friendly 'Hello World' message", (done) ->
        phantom.create (ph) ->
            sharedPhantom = ph
            sharedPhantom.createPage (page) ->
                page.open "http://localhost:#{config.get 'app:port'}/", (status) ->
                    expect(status).to.equal('success')
                    page.evaluate ( evaluatePage ), (result) ->
                        expect(result).to.have.string('Hello World')
                        done()

evaluatePage = ->
    return document.querySelector('.content span').innerText