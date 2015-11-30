http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
iri = require 'iri'

describe 'GET /aliases/micrometeor', ->
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

  context 'when the alias exists', ->
    context 'an ascii name', ->
      beforeEach (done) ->
        newAlias =
          name: 'micrometeor'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: 'ejected.from.airlock'
            uuid: '97e0f23c-2219-4803-ac85-81ed221d10e2'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: '899801b3-e877-4c69-93db-89bd9787ceea'
          password: 'user-token'

        options =
          auth: auth
          json: true

        request.get "http://localhost:#{@serverPort}/aliases/micrometeor?name=ejected.from.airlock", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'return an alias', ->
        expect(@body).to.contain name: 'ejected.from.airlock', uuid: '97e0f23c-2219-4803-ac85-81ed221d10e2'

    context 'a unicode name', ->
      beforeEach (done) ->
        newAlias =
          name: '💩'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: '💩.💩'
            uuid: '97e0f23c-2219-4803-ac85-81ed221d10e2'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: '899801b3-e877-4c69-93db-89bd9787ceea'
          password: 'user-token'

        options =
          auth: auth
          json: true

        path = new iri.IRI "http://localhost:#{@serverPort}/aliases/💩?name=💩.💩"

        request.get path.toURIString(), options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 200', ->
        expect(@response.statusCode).to.equal 200

      it 'return an alias', ->
        expect(@body).to.contain name: '💩.💩', uuid: '97e0f23c-2219-4803-ac85-81ed221d10e2'

  context 'when the alias does not exists', ->
    beforeEach (done) ->
      auth =
        username: '899801b3-e877-4c69-93db-89bd9787ceea'
        password: 'user-token'

      options =
        auth: auth
        json: true

      request.get "http://localhost:#{@serverPort}/aliases/car-over-cliff", options, (error, @response, @body) =>
        done error

    it 'should authenticate with meshblu', ->
      expect(@whoamiHandler.isDone).to.be.true

    it 'should respond with 404', ->
      expect(@response.statusCode).to.equal 404

    it 'should not return an alias', ->
      expect(@body).to.be.undefined

  context 'when the sub-alias does not exists', ->
    beforeEach (done) ->
      newAlias =
        name: 'micrometeor'
        uuid: '21560426-7338-450d-ab10-e477ef1908a6'
        owner: '899801b3-e877-4c69-93db-89bd9787ceea'
        subaliases: []

      @datastore.insert newAlias, (error, @alias) =>
        done error

    beforeEach (done) ->
      auth =
        username: '899801b3-e877-4c69-93db-89bd9787ceea'
        password: 'user-token'

      options =
        auth: auth
        json: true

      request.get "http://localhost:#{@serverPort}/aliases/micrometeor?name=insufficient.heat.shielding", options, (error, @response, @body) =>
        done error

    it 'should authenticate with meshblu', ->
      expect(@whoamiHandler.isDone).to.be.true

    it 'should respond with 404', ->
      expect(@response.statusCode).to.equal 404

    it 'should not return an alias', ->
      expect(@body).to.be.undefined
