http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'

describe 'POST /aliases/chloroform', ->
  beforeEach ->
    @meshblu = shmock 0xd00d

  afterEach (done) ->
    @meshblu.close => done()

  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: 0xd00d

    serverOptions =
      port: undefined,
      disableLogging: true
      meshbluConfig: meshbluConfig
      mongoDbUri: 'mongodb://127.0.0.1/test-uuid-alias-service'

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  beforeEach ->
    @whoamiHandler = @meshblu.get('/v2/whoami')
      .reply(200, '{"uuid": "899801b3-e877-4c69-93db-89bd9787ceea"}')

  beforeEach (done) ->
    @datastore = new Datastore
      database: mongojs 'mongodb://127.0.0.1/test-uuid-alias-service'
      collection: 'aliases'
    @datastore.remove {}, (error) => done() # delete everything

  afterEach (done) ->
    @server.stop => done()

  context 'when given a valid sub alias', ->
    context 'when the alias exists', ->
      beforeEach (done) ->
        @datastore.insert name: 'chloroform', uuid: '21560426-7338-450d-ab10-e477ef1908a6', owner: '899801b3-e877-4c69-93db-89bd9787ceea', subaliases: [], (error, @alias) =>
          done error

      context 'an ascii name', ->
        beforeEach (done) ->
          auth =
            username: '899801b3-e877-4c69-93db-89bd9787ceea'
            password: 'user-token'

          alias =
            name: 'undeterred.by.lack.of.training'
            uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

          options =
            auth: auth
            json: alias

          request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
            done error

        beforeEach (done) ->
          @datastore.findOne name: 'chloroform', (error, @alias) =>
            done error

        it 'should call the whoamiHandler', ->
          expect(@whoamiHandler.isDone).to.be.true

        it 'should respond with a 201', ->
          expect(@response.statusCode).to.equal 201

        it 'create an alias in mongo', ->
          expect(@alias.subaliases).to.contain name: 'undeterred.by.lack.of.training', uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

      context 'a unicode name', ->
        beforeEach (done) ->
          auth =
            username: '899801b3-e877-4c69-93db-89bd9787ceea'
            password: 'user-token'

          alias =
            name: '☃.💩'
            uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

          options =
            auth: auth
            json: alias

          request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
            done error

        beforeEach (done) ->
          @datastore.findOne name: 'chloroform', (error, @alias) =>
            done error

        it 'should call the whoamiHandler', ->
          expect(@whoamiHandler.isDone).to.be.true

        it 'should respond with a 201', ->
          expect(@response.statusCode).to.equal 201

        it 'create an alias in mongo', ->
          expect(@alias.subaliases).to.contain name: '☃.💩', uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

      context 'when given an invalid sub-alias', ->
        context 'when given a UUID as a name', ->
          beforeEach (done) ->
            auth =
              username: '899801b3-e877-4c69-93db-89bd9787ceea'
              password: 'user-token'

            alias =
              name: 'c38b942c-f851-4ef8-a5a0-65b0ea960a4c'
              uuid: '48162884-d42f-4110-bdb2-9d17db996993'

            options =
              auth: auth
              json: alias

            request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
              done error

          beforeEach (done) ->
            @datastore.findOne name: 'chloroform', (error, @alias) =>
              done error

          it 'should call the whoamiHandler', ->
            expect(@whoamiHandler.isDone).to.be.true

          it 'should respond with a 422', ->
            expect(@response.statusCode).to.equal 422

          it 'should not create an alias in mongo', ->
            expect(@alias.subaliases).to.not.contain name: 'c38b942c-f851-4ef8-a5a0-65b0ea960a4c'

        context 'when given an empty name', ->
          beforeEach (done) ->
            auth =
              username: '899801b3-e877-4c69-93db-89bd9787ceea'
              password: 'user-token'

            alias =
              name: undefined
              uuid: 'ecca684d-68ba-47d9-bb93-5124f20936cc'

            options =
              auth: auth
              json: alias

            request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
              done error

          beforeEach (done) ->
            @datastore.findOne name: 'chloroform', (error, @alias) =>
              done error

          it 'should call the whoamiHandler', ->
            expect(@whoamiHandler.isDone).to.be.true

          it 'should respond with a 422', ->
            expect(@response.statusCode).to.equal 422

          it 'should not create an alias in mongo', ->
            expect(@alias.subaliases).to.not.contain name: undefined

        context 'when given an empty uuid', ->
          beforeEach (done) ->
            auth =
              username: '899801b3-e877-4c69-93db-89bd9787ceea'
              password: 'user-token'

            alias =
              name: 'burlap-sack'
              uuid: undefined

            options =
              auth: auth
              json: alias

            request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
              done error

          beforeEach (done) ->
            @datastore.findOne name: 'chloroform', (error, @alias) =>
              done error

          it 'should call the whoamiHandler', ->
            expect(@whoamiHandler.isDone).to.be.true

          it 'should respond with a 422', ->
            expect(@response.statusCode).to.equal 422

          it 'should not create an alias in mongo', ->
            expect(@alias.subaliases).to.not.contain name: 'burlap-sack'

        context 'when given non-uuid as the uuid', ->
          beforeEach (done) ->
            auth =
              username: '899801b3-e877-4c69-93db-89bd9787ceea'
              password: 'user-token'

            alias =
              name: 'burlap-sack'
              uuid: 'billy-club'

            options =
              auth: auth
              json: alias

            request.post "http://localhost:#{@serverPort}/aliases/chloroform", options, (error, @response, @body) =>
              done error

          beforeEach (done) ->
            @datastore.findOne name: 'chloroform', (error, @alias) =>
              done error

          it 'should call the whoamiHandler', ->
            expect(@whoamiHandler.isDone).to.be.true

          it 'should respond with a 422', ->
            expect(@response.statusCode).to.equal 422

          it 'should not create an alias in mongo', ->
            expect(@alias.subaliases).to.not.contain name: 'burlap-sack'

  context 'when given a valid sub alias', ->
    context 'when the alias does not exist', ->
      context 'an ascii name', ->
        beforeEach (done) ->
          auth =
            username: '899801b3-e877-4c69-93db-89bd9787ceea'
            password: 'user-token'

          alias =
            name: 'undeterred.by.lack.of.training'
            uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

          options =
            auth: auth
            json: alias

          request.post "http://localhost:#{@serverPort}/aliases/velocity", options, (error, @response, @body) =>
            done error

        it 'should call the whoamiHandler', ->
          expect(@whoamiHandler.isDone).to.be.true

        it 'should respond with a 404', ->
          expect(@response.statusCode).to.equal 404

  context 'when a different user', ->
    context 'when the alias exists', ->
      beforeEach (done) ->
        @datastore.insert name: 'poor-trunk-ventilation', uuid: '21560426-7338-450d-ab10-e477ef1908a6', owner: '899801b3-e877-4c69-93db-89bd9787ceea', subaliases: [], (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'd9233797-95e5-44f8-9f33-4f3af80d436d'
          password: 'other-user-token'

        alias =
          name: 'accident'
          uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases/poor-trunk-ventilation", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 403', ->
        expect(@response.statusCode).to.equal 403

      beforeEach (done) ->
        @datastore.findOne name: 'poor-trunk-ventilation', (error, @alias) =>
          done error

      it 'should not add a subalias in mongo', ->
        expect(@alias.subaliases).to.not.contain name: 'accident', uuid: '65255089-6ed8-4a75-853a-90825a6525c3'
