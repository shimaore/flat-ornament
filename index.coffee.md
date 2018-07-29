Legacy parser
-------------

This is the legacy parser for flat-ornament. It supports ornaments stored as a data structure, including where parts of the data structure are replaced by strings, which are parsed using the simple language defined in `language.jison`, which was meant to generate content identical to the data structure. (This was originally meant to allow tools to go back-and-forth between the data structure and the textual representations.)

    {@name} = require './package'

    {Parser} = require './language'

    NOTHING = ->
    NOT = (x) -> not x
    ID = (x) -> x

    parser = (commands) ->

      p = new Parser()
      p.yy.op = commands
      p

    compile = (ornaments,commands,parser) ->

      switch
        when typeof ornaments is 'string'
          parser.parse "ornaments #{ornaments}"

        when ornaments.length?

          structure = ornaments.map (ornament) ->
            compile_ornament ornament,commands,parser

          ->
            for ornament in structure
              if await ornament.call this
                return

        else
          NOTHING

Each ornament is a list of statements which are executed in order.

A statement consists of:
- a `type` (the command to be executed);
- optional `param` or `params[]` (parameters for the command);
- optional `not` (to reverse the outcome).
Execution continues as long as the outcome of a statement is true.

Normally conditions are listed first, while actions are listed last, but really we don't care.

Applying `not` to an action probably won't do what you expect.

Return true if a command returned `over`, indicating the remaining ornaments in the list should be skipped.

    compile_ornament = (ornament,commands,parser) ->

      switch
        when typeof ornament is 'string'
          parser.parse "ornament #{ornament}"

        when ornament.length?

          structure = ornament.map (statement) ->
            compile_statement statement,commands,parser

This function return `true` if the execution should stop.

          ->
            for statement in structure

              truth = await statement.call this
              return true if truth is 'over'

              truth = not truth if statement.not

Terminate the ornament and continue to the next one, if any condition or action returned false.

              return false unless truth

If no precondition / postcondition / action returned false, continue to the next ornament.

            return false

        else
          NOTHING

    compile_statement = (statement,commands,parser) ->

A statement might be a `{type,param?,params?,not?}` object, or a `[('not',)type,params...]` array, or a `"(not )type( param param …)"` string.
All statements are converted to `{type,param?,params?,not}` for evaluation.

      switch

String statement

        when typeof statement is 'string'
          parser.parse "statement #{statement}"

Array statement

        when statement.length?

          params = statement[..]
          if params[0] is 'not'
            params.shift()
            truthy = NOT
          else
            truthy = ID

          type = params.shift()
          return NOTHING unless type?
          c = commands[type]
          return NOTHING unless c?

          -> truthy await c.apply this, params

Object statement

        else

          {type} = statement
          return NOTHING unless type?
          c = commands[type]
          return NOTHING unless c?

          truthy = if statement.not then NOT else ID

          switch
            when statement.params?
              -> truthy await c.apply this, statement.params
            when statement.param?
              -> truthy await c.call this, statement.param
            else
              -> truthy await c.call this

    run = (ornaments,commands) ->
      (compile ornaments, commands, parser commands).call this

    module.exports = {run,parser,compile}
