    ({expect} = chai = require 'chai').should()
    chai.use(require 'chai-as-promised')

    describe 'Language 2', ->
      it 'should load', ->
        require '../language2'
      describe 'should parse simple expressions', ->
        {Parser} = require '../language2'
        parser = new Parser()
        parser.yy.op =
          promise: (x) ->
            Promise.resolve x
          sqrt: (x) -> Math.sqrt x
          get: (n) -> this.get n
          set: (n,v) -> this.set(n, v); v
          animal: -> this.get 'ant'

        state = new Map [['bear',4], ['ant',3]]
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
          expect(await pp '3+promise(4)').to.equal 7
          expect(await pp 'promise(3) and promise(4)').to.equal 4
        it 'should do variables', ->
          expect(await pp 'foo = "hello ", foo + "world"').to.equal 'hello world'
          expect(await pp 'foo = "hello ", promise(foo + "world")').to.equal 'hello world'
          expect(await pp '
            a = 1,
            b = 3,
            c = 6.7,
            a+b+c
          ').to.equal 10.7
          expect(await pp '
            n = 2,
            n = n-1,
            n = n+4,
            n*5
          ').to.equal 25
        it 'should do conditionals', ->
          expect(await pp '
            foo = "hello ",
            if sqrt(42) > 5 then promise(foo + "world") else "pooh"
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
          expect(state.get 'bear').to.equal 42
          expect(await pp '
            a = 3,
            b = true,
            if b then set("dog",get("bear")*a)
          ').to.equal 126
          expect(state.get 'bear').to.equal 42
          expect(state.get 'dog').to.equal 126
          expect(await pp '
            animal
          ').to.equal state.get 'ant'

        it 'should postpone', ->
          expect(await pp '
            close = postpone ( a = 2*b, a+c ),
            close( b= 4, c: 10 )
          ').to.equal 2*4+10
        it 'should postpone and accept parameter evaluation', ->
          await (pp '
            close = postpone ( a = 2*b, a+c ),
            close( b= 43*get("ant"), c: 10 )
          ').should.eventually.equal 2*43*state.get('ant')+10
          await (pp '
            mul = → a*b,
            add = → a+b,
            add(a=3,b:4)
          ').should.eventually.equal 3+4
          await (pp '
            mul = → a*b,
            add = → a+b,
            mul(a:3,b=4)
          ').should.eventually.equal 3*4
          await (pp '
            mul = → a*b,
            add = → a+b,
            mul(a:3,b=add(a=1,b:3))
          ').should.eventually.equal 3*4
          await (pp '
            mul = → a*b,
            add = → a+b,
            mul( a:add(a=3,b=4), b=add(b:8,a=6) )
          ').should.eventually.equal (3+4)*(6+8)

The language is complex enough to support recursion.
Of course since the goal is to process calls and not let outsiders bring the system down, that's probably too much power.
(Essentially we're trying to build a language in which termination is decidable.)

        it 'should not recurse (Peter-Ackermann)', ->
          (pp '
            A = →
              if m is 0 then n+1 else
              if m > 0 and n is 0 then A(A:A,m:m-1,n:n-1) else
              if m > 0 and n > 0 then A(A:A,m:m-1,n:A(A:A,m:m,n:n-1)),

            A(A:A,m:4,n:3)
          ').should.be.rejected
        it 'should not recurse (factorial 1)', ->
          (pp '
            fact = → if n > 0 then n*fact(fact:fact,n:n-1) else 1,
            fact(fact:fact, n:1)
          ').should.be.rejected
        it 'should not recurse (factorial 10000)', ->
          (pp '
            fact = → if n > 0 then n*fact(fact:fact,n:n-1) else 1,
            fact(fact:fact, n:10000)
          ').should.be.rejected

        it 'should support objects', ->
          (pp '
            the a of {a:3,b:4}
          ').should.eventually.equal 3
        it 'should support objects size', ->
          (pp '
            the size of {a:3,b:4}
          ').should.eventually.equal 2
        it 'should support complex objects', ->
          (pp '''
            the name of the owner of the dog of { dog: { name: 'Milou', owner: { name: 'Tintin' } } }
          ''').should.eventually.equal 'Tintin'
        it 'should handle arrays', ->
          (pp '''
            the length of ['a','b','c']
          ''').should.eventually.equal 3
        it 'should handle arrays', ->
          (pp '''
            ['a','b','c'][2]
          ''').should.eventually.equal 'c'
        it 'should handle arrays', ->
          (pp '''
            ['a','b','c'][2]
          ''').should.eventually.equal 'c'
