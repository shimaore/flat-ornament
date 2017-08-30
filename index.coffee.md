    seem = require 'seem'
    @name = (require './package').name
    debug = (require 'tangible') @name

    {Parser} = require './language'

Run
---

Parameter: an array of individual ornaments which are executed in the order of the array.
If any ornament return `true`, skip the remaining ornaments in the list.

    module.exports = seem (ornaments,commands) ->
      return unless ornaments?

      parser = new Parser()
      parser.yy.valid_op = commands

      if typeof ornaments is 'string'
        ornaments = parser.parse "COMPILE ORNAMENTS #{ornaments}"
        debug 'ornament', ornaments

      debug 'Processing', ornaments

      for ornament in ornaments
        debug 'ornament', ornament
        over = yield do (ornament) => execute.call this, ornament, commands, parser
        debug 'over', over
        return if over

      return

Execute
-------

Each ornament is a list of statements which are executed in order.

A statement consists of:
- a `type` (the command to be executed);
- optional `param` or `params[]` (parameters for the command);
- optional `not` (to reverse the outcome).
Execution continues as long as the outcome of a statement is true.

Normally conditions are listed first, while actions are listed last, but really we don't care.

Applying `not` to an action probably won't do what you expect.

Return true if a command returned `over`, indicating the remaining ornaments in the list should be skipped.

    execute = seem (ornament,commands,parser) ->

      if typeof ornament is 'string'
        ornament = parser.parse "COMPILE ORNAMENT #{ornament}"
        debug 'ornament', ornament

      for statement in ornament

A statement might be a {type,param?,params?,not?} object, or a [('not',)type,params...] array, or a "(not )type( param param …)" string.

        if typeof statement is 'string'
          statement = parser.parse "COMPILE STATEMENT #{statement}"
          debug 'statement', statement

        if statement.length?
          params = statement[..]
          statement = {}
          if params[0] is 'not'
            params.shift()
            statement.not = true
          statement.type = params.shift()
          statement.params = params

        unless statement.type?
          debug 'No command', statement
          return false

        c = commands[statement.type]

Terminate the ornament and continue to the next one, if the command is invalid.

        unless c?
          debug 'No such command', statement.type
          return false

Evaluate based on the presence of `params[]` or `param`.

        switch
          when statement.params?
            debug "Calling #{statement.type}", statement.params
            truth = yield c.apply this, statement.params
          when statement.param?
            debug "Calling #{statement.type}", statement.param
            truth = yield c.call this, statement.param
          else
            debug "Calling #{statement.type} (no arguments)"
            truth = yield c.call this

DEPRECATED: truth should be a boolean; this will soon change to `return truth if typeof truth isnt 'boolean'`.

        if truth is 'over'
          return true

        truth = not truth if statement.not

Terminate the ornament and continue to the next one, if any condition or action returned false.

        return false unless truth

If no precondition / postcondition / action returned false, continue to the next ornament.

      return false
