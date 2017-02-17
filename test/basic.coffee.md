    chai = require 'chai'
    chai.should()
    seem = require 'seem'

    describe 'Run', ->
      run = require '..'
      it 'should process no ornaments', ->
        run.call {}, []

      it 'should process one ornament with one statement', seem ->
        ctx = {}
        yield run.call ctx, [[ type:'1' ]],
          1: ->
            @bear = 'big'
            true

        ctx.should.have.property 'bear', 'big'

      it 'should process one ornament with one statement as string', seem ->
        ctx = {}
        yield run.call ctx, [['1']],
          1: ->
            @bear = 'big'
            true

        ctx.should.have.property 'bear', 'big'

      it 'should process one ornament with statements as strings', seem ->
        ctx = {}
        yield run.call ctx, [['not inc','inc','inc']],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 1

      it 'should process one ornament with statements as strings', seem ->
        ctx = {}
        yield run.call ctx, [['inc','not inc','inc']],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 2

      it 'should process one ornament with statements as arrays', seem ->
        ctx = {}
        yield run.call ctx, [[['not','inc'],['inc'],['inc']]],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 1

      it 'should process one statement with `not` command', seem ->
        ctx = {}
        yield run.call ctx, [[['not','inc'],['inc'],['inc']]],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 1

      it 'should process one ornament with multiple statements', seem ->
        ctx = {}
        yield run.call ctx, [[type:'inc'],[type:'inc'],[type:'inc']],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 3

      it 'should process one statement with multiple commands', seem ->
        ctx = {}
        yield run.call ctx, [[{type:'inc'},{type:'inc'},{type:'inc'}]],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 3

      it 'should process one statement with `not` command', seem ->
        ctx = {}
        yield run.call ctx, [[{not:true,type:'inc'},{type:'inc'},{type:'inc'}]],
          inc: ->
            @bear ?= 0
            @bear++
            true

        ctx.should.have.property 'bear', 1

      commands =
        one_more_cookie: -> @cookies++; true
        give_milk: (how_much) -> @milk = how_much; true
        if_little: -> @bear is 'little'
        if_big: -> @bear is 'big'
        if_nice: -> @bear is 'nice'
        if_angry: -> @bear is 'angry'
        stop: -> false
        over: -> 'over'
        pet: -> @pet = true; true

      it 'should process multiple ornaments', seem ->
        ornaments = [
          [{type:'if_little'},{type:'one_more_cookie'}]
          [{type:'if_big'},{type:'give_milk',param:'plenty'},{type:'over'}]
          [{type:'if_nice'},{type:'one_more_cookie'},{type:'one_more_cookie'},{type:'give_milk',params:['some']}]
          [{type:'if_angry'},{type:'one_more_cookie'},{type:'stop'},{type:'one_more_cookie'},{type:'give_milk',params:['maybe']}]
          [{type:'pet'}]
        ]

        ctx = {bear:'little',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 1
        ctx.should.have.property 'milk', false
        ctx.should.have.property 'pet', true

        ctx = {bear:'big',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 0
        ctx.should.have.property 'milk', 'plenty'
        ctx.should.not.have.property 'pet'

        ctx = {bear:'nice',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 2
        ctx.should.have.property 'milk', 'some'
        ctx.should.have.property 'pet', true

        ctx = {bear:'angry',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 1
        ctx.should.have.property 'milk', false
        ctx.should.have.property 'pet', true

      it 'should process multiple ornaments (arrays)', seem ->
        ornaments = [
          [['if_big'],['give_milk','plenty'],['over']]
          [['pet']]
        ]

        ctx = {bear:'little',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'pet', true

        ctx = {bear:'big',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 0
        ctx.should.have.property 'milk', 'plenty'
        ctx.should.not.have.property 'pet'

      it 'should process multiple ornaments (mixed)', seem ->
        ornaments = [
          ['if_little','one_more_cookie']
          ['if_big',['give_milk','plenty'],'over']
          ['if_nice','one_more_cookie','one_more_cookie','give_milk some']
          ['if_angry','one_more_cookie','stop','one_more_cookie',['give_milk','maybe']]
          ['pet']
        ]

        ctx = {bear:'little',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 1
        ctx.should.have.property 'milk', false
        ctx.should.have.property 'pet', true

        ctx = {bear:'big',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 0
        ctx.should.have.property 'milk', 'plenty'
        ctx.should.not.have.property 'pet'

        ctx = {bear:'nice',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 2
        ctx.should.have.property 'milk', 'some'
        ctx.should.have.property 'pet', true

        ctx = {bear:'angry',cookies:0,milk:false}
        yield run.call ctx, ornaments, commands
        ctx.should.have.property 'cookies', 1
        ctx.should.have.property 'milk', false
        ctx.should.have.property 'pet', true
