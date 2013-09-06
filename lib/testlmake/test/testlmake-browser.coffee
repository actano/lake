
me = require 'testlmake'
new me()

# @see client.coffee
describe 'testlmake', ->

    it 'should contain hello world the content element', (done) ->

        text = $('.content span').text()
        expect(text).to.be.equal('Hello World')
        done()

    it 'test templates with bind-jade', (done) ->
        list = $('.testlmake ul.content')
        length = list.children().length
        expect(length).to.be.equal(5)
        done()

    it 'test css from a dependency', (done) ->
        list = $('.testlmake ul.content')
        whiteSpace = list.css('white-space')
        expect(whiteSpace).to.be.equal('nowrap')
        done()

    it 'test markup of a dependency after it was modified', (done) ->
        hellodiv = $('.empty')
        expect(hellodiv.text()).to.be.equal('I am here')
        done()