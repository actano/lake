jade = require 'jade-runtime'

module.exports = (f) ->
    (locals) ->
        f locals, jade.attrs, jade.escape, jade.rethrow, jade.merge
