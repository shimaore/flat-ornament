This is a compiler for the new content.

Basically we support two (actually three) formats:
- the original Array format from ornaments, way back
- ornaments-as-a-string-to-be-compiled
- and the newer layout, which is an Object with a `language` tag and a `script` tag.

    default_compilers =
      ornaments: (src,commands) ->
        parser = ornaments.parser commands
        ornaments.compile src, commands, parser
      v1: (src,commands) ->
        # parser = ornaments.parser commands
        parser = new language1.Parser()
        parser.yy.op = commands
        parser.parse src
      v2: (src,commands) ->
        parser = new language2.Parser()
        parser.yy.op = commands
        parser.parse src

    ornaments = require './index'
    language1 = require './language'
    language2 = require './language2'

    module.exports = compile = (source,commands,compilers = {}) ->
      Object.assign compilers, default_compilers
      switch
        when source.language?
          compilers[source.language]? source.script, commands
        else
          compilers.ornaments source, commands
