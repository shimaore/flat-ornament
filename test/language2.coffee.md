    {expect} = chai = require 'chai'
    chai.should()

    describe 'Language 2', ->
      it 'should load', ->
        require '../language2'
      it 'should parse simple expressions', ->
        {Parser} = require '../language2'
        parser = new Parser()
        parser.yy.Immutable = require 'immutable'
        parser.yy.valid_op =
          long: (x) ->
            Promise.resolve x
          sqrt: (x) -> Math.sqrt x

        pp = (x) -> parser.parse x
        expect(await pp '3').to.equal 3
        expect(await pp 'true').to.equal true
        expect(await pp 'false').to.equal false
        expect(await pp '"hello"').to.equal 'hello'
        expect(await pp "'hello'").to.equal 'hello'
        expect(await pp '34.5').to.equal 34.5

        expect(await pp '3+4').to.equal 7
        expect(await pp '-3+4').to.equal 1
        expect(await pp 'sqrt(49)').to.equal 7
        expect(await pp '3+long(4)').to.equal 7
        expect(await pp 'long(3) and long(4)').to.equal 4
        expect(await pp 'foo = "hello ", foo + "world"').to.equal 'hello world'
        expect(await pp 'foo = "hello ", long(foo + "world")').to.equal 'hello world'
        expect(await pp '
          foo = "hello ",
          if sqrt(42) > 5 then long(foo + "world") else "pooh"
        ').to.equal 'hello world'
        expect(await pp '
          if 3 > 4 then "ok" else "no"
        ').to.equal 'no'
        expect(await pp '
          if 3 > 4 then true else false
        ').to.equal false
        expect(await pp '
          if 3 > 4 then true else false if false
        ').to.equal undefined
        expect(await pp '
          if 3 > 4 then true else false if true
        ').to.equal false
        expect(await pp '
          bear = 42,
          if it > 42 then true else false
        ').to.equal false
        expect(await pp '
          the length of "hello"
        ').to.equal 5
        expect(await pp '
          the length of [0,1,2,3]
        ').to.equal 4
        expect(await pp '
          ["a","b","c","d"][2]
        ').to.equal 'c'
