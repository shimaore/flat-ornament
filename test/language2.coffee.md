    {expect} = chai = require 'chai'
    chai.should()

    describe 'Language 2', ->
      it 'should load', ->
        require '../language2'
      describe 'should parse simple expressions', ->
        {Parser} = require '../language2'
        parser = new Parser()
        parser.yy.op =
          postpone: (x) ->
            Promise.resolve x
          sqrt: (x) -> Math.sqrt x
          get: (n) -> this[n]
          set: (n,v) -> this[n] = v
          animal: -> this.ant

        state = bear: 4, ant: 3
        pp = (x) -> (parser.parse x).call state
        it 'should parse integer', ->
          expect(await pp '3').to.equal 3
        it 'should parse booleans', ->
          expect(await pp 'true').to.equal true
          expect(await pp 'false').to.equal false
        it 'should parse string', ->
          expect(await pp '"hello"').to.equal 'hello'
          expect(await pp "'hello'").to.equal 'hello'
        it 'should parse float', ->
          expect(await pp '34.5').to.equal 34.5

        it 'should do arithmetic', ->
          expect(await pp '3+4').to.equal 7
          expect(await pp '-3+4').to.equal 1
        it 'should do function call', ->
          expect(await pp 'sqrt(49)').to.equal 7
          expect(await pp '3+postpone(4)').to.equal 7
          expect(await pp 'postpone(3) and postpone(4)').to.equal 4
        it 'should do variables', ->
          expect(await pp 'foo = "hello ", foo + "world"').to.equal 'hello world'
          expect(await pp 'foo = "hello ", postpone(foo + "world")').to.equal 'hello world'
          expect(await pp '
            a = 1,
            b = 3,
            c = 6.7,
            a+b+c
          ').to.equal 10.7
        it 'should do conditionals', ->
          expect(await pp '
            foo = "hello ",
            if sqrt(42) > 5 then postpone(foo + "world") else "pooh"
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
        it 'should do field access', ->
          expect(await pp '
            the length of "hello"
          ').to.equal 5
          expect(await pp '
            the length of [0,1,2,3]
          ').to.equal 4
          expect(await pp '
            ["a","b","c","d"][2]
          ').to.equal 'c'
          expect(await pp '
            get("bear")
          ').to.equal 4
          expect(await pp '
            set("bear",42)
          ').to.equal 42
          state.should.have.property 'bear', 42
          expect(await pp '
            a = 3,
            b = true,
            if b then set("dog",get("bear")*a)
          ').to.equal 126
          state.should.have.property 'bear', 42
          state.should.have.property 'dog', 126
          expect(await pp '
            animal
          ').to.equal state.ant
