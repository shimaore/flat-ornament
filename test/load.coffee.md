    ({expect} = require 'chai').should()

    describe 'The module', ->
      it 'should load', ->
        require '../index'

      it 'should compile', ->

        compile = require '../compile'

        fun = compile {language:'v2',script:'3 + 4'}, {}
        expect(typeof fun).to.equal 'function'

        expect(await fun()).to.equal 7
