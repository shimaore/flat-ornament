// Generated by CoffeeScript 2.3.2
(function() {
  // This is a compiler for the new content.

  // Basically we support two (actually three) formats:
  // - the original Array format from ornaments, way back
  // - ornaments-as-a-string-to-be-compiled
  // - and the newer layout, which is an Object with a `language` tag and a `script` tag.
  var compile, default_compilers, language1, language2, ornaments;

  default_compilers = {
    ornaments: function(src, commands) {
      var parser;
      parser = ornaments.parser(commands);
      return ornaments.compile(src, commands, parser);
    },
    v1: function(src, commands) {
      var parser;
      // parser = ornaments.parser commands
      parser = new language1.Parser();
      parser.yy.op = commands;
      return parser.parse(src);
    },
    v2: function(src, commands) {
      var parser;
      parser = new language2.Parser();
      parser.yy.op = commands;
      return parser.parse(src);
    }
  };

  ornaments = require('./index');

  language1 = require('./language');

  language2 = require('./language2');

  module.exports = compile = function(source, commands, compilers = {}) {
    var name;
    Object.assign(compilers, default_compilers);
    switch (false) {
      case source.language == null:
        return typeof compilers[name = source.language] === "function" ? compilers[name](source.script, commands) : void 0;
      default:
        return compilers.ornaments(source, commands);
    }
  };

}).call(this);
