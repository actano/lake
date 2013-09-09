path = require 'path'
http = require 'http'
express = require 'express'

config = require '../config'

http_port = config.get "app:port"

module.exports = app = express()

app.use express.static path.join __dirname, 'build'
app.use express.bodyParser()
app.use express.cookieParser()
app.use app.router
app.use express.errorHandler()
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

# routes
app.get '/testlmake-trans-dep', (req, res) ->
    res.json {message: "Hello World"}

# if the module is run (rather than required) we start a small httpd server
# for rapid prototyping and testing

if require.main is module

    app.get '/', (req, res) -> res.render 'demo'

    console.log "stand-alone server running."
    console.log "try http://localhost:#{http_port}/"
    app.listen http_port