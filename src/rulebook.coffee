class RuleBook

    constructor: ->
        @rules = []
        @closed = false

    # this method actually adds a FACTORY for a rule
    addRule: (rule) ->
        if @closed
            throw new Error 'RuleBook is already closed, ' +
                'you can\'t add rules anymore'

        @rules.push rule if rule?

    close: ->
        @closed = true

    getRules: ->
        return @rules

module.exports = RuleBook