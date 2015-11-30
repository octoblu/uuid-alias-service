http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'

describe 'POST /aliases', ->
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
      .reply(200, '{"uuid": "user-uuid"}')

  beforeEach (done) ->
    @datastore = new Datastore
      database: mongojs 'mongodb://127.0.0.1/test-uuid-alias-service'
      collection: 'aliases'
    @datastore.remove {}, (error) => done() # delete everything

  afterEach (done) ->
    @server.stop => done()

  context 'when given a valid alias', ->
    context 'an ascii name', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: 'premature-burial'
          uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: 'premature-burial', (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'create an alias in mongo', ->
        expect(@alias).to.contain name: 'premature-burial', uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2', owner: 'user-uuid'

    context 'a unicode name', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: '☃'
          uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: '☃', (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'create an alias in mongo', ->
        expect(@alias).to.contain name: '☃', uuid: 'b38d4757-6f91-4aee-8ffb-ff53abc796a2', owner: 'user-uuid'

  context 'when given an invalid alias', ->
    context 'when given a UUID as a name', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: 'c38b942c-f851-4ef8-a5a0-65b0ea960a4c'
          uuid: '48162884-d42f-4110-bdb2-9d17db996993'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: 'c38b942c-f851-4ef8-a5a0-65b0ea960a4c', (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 422', ->
        expect(@response.statusCode).to.equal 422

      it 'should not create an alias in mongo', ->
        expect(@alias).to.not.exist

    context 'when given an empty name', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: undefined
          uuid: 'ecca684d-68ba-47d9-bb93-5124f20936cc'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: undefined, (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 422', ->
        expect(@response.statusCode).to.equal 422

      it 'should not create an alias in mongo', ->
        expect(@alias).to.not.exist

    context 'when given an empty uuid', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: 'burlap-sack'
          uuid: undefined

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: 'burlap-sack', (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 422', ->
        expect(@response.statusCode).to.equal 422

      it 'should not create an alias in mongo', ->
        expect(@alias).to.not.exist

    context 'when given non-uuid as the uuid', ->
      beforeEach (done) ->
        auth =
          username: 'user-uuid'
          password: 'user-token'

        alias =
          name: 'burlap-sack'
          uuid: 'billy-club'

        options =
          auth: auth
          json: alias

        request.post "http://localhost:#{@serverPort}/aliases", options, (error, @response, @body) =>
          done error

      beforeEach (done) ->
        @datastore.findOne name: 'burlap-sack', (error, @alias) =>
          done error

      it 'should call the whoamiHandler', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with a 422', ->
        expect(@response.statusCode).to.equal 422

      it 'should not create an alias in mongo', ->
        expect(@alias).to.not.exist
