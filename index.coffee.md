    seem = require 'seem'
    @name = (require './package').name
    debug = (require 'debug') @name

Run
---

Parameter: an array of individual ornaments which are executed in the order of the array.
If any ornament return `true`, skip the remaining ornaments in the list.

    @run = seem (ornaments) ->
      return unless ornaments?

      debug 'Processing'

      for ornament in ornaments
        debug 'ornament', ornament
        over = yield do (ornament) => execute.call this, ornament
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

    execute = seem (ornament) =>

      for statement in ornament
        c = commands[statement.type]

Terminate the ornament and continue to the next one, if the command is invalid.

        return false unless c?

Evaluate based on the presence of `params[]` or `param`.

        switch
          when statement.params?
            truth = yield c.apply this, statement.params
          when statement.param?
            truth = yield c.call this, statement.param
          else
            truth = yield c.call this

        if truth is 'over'
          return true

        truth = not truth if statement.not

Terminate the ornament and continue to the next one, if any condition or action returned false.

        return false unless truth

If no precondition / postcondition / action returned false, continue to the next ornament.

      return false



