app = require '../server'

request = require 'supertest'
{expect} = require 'chai'
{inspect} = require 'util'

# @see server.coffee
describe 'testlmake-dep REST API', ->

    # TODO: make a real test
    it 'should return a friendly message from the route /helloworld', (done) ->
        request(app)
            .get('/testlmake-dep')
            .end (err, res) ->
                expect(res.status).to.equal 200
                expect(res.body).to.exist
                expect(res.body.message).to.exist
                expect(res.body.message).to.be.a 'string'
                expect(res.body.message).to.equal 'Hello World'
                done(err)

