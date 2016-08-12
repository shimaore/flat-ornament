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

        ctx.should.have.property 'bear', 'big'

      it 'should process one ornament with multiple statements', seem ->
        ctx = {}
        yield run.call ctx, [[type:'inc'],[type:'inc'],[type:'inc']],
          inc: ->
            @bear ?= 0
            @bear++

        ctx.should.have.property 'bear', 3

      it 'should process multiple ornaments', seem ->
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
