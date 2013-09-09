
me = require 'testlmake-trans-dep'
new me()

# @see client.coffee
describe 'testlmake-trans-dep', ->

    it 'should contain hello world the content element', (done) ->

        text = $('.content span').text()
        expect(text).to.be.equal('Hello World')
        done()

    it.skip 'TODO: test something', (done) ->
        expect('this test').to.be.equal('a real test')
        done()
