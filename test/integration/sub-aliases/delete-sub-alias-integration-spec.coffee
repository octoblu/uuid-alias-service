http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
iri = require 'iri'

describe 'DELETE /aliases/lack-of-lifeboats?name=deep.freeze', ->
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
          name: 'lack-of-lifeboats'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: 'deep.freeze'
            uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
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

        request.del "http://localhost:#{@serverPort}/aliases/lack-of-lifeboats?name=deep.freeze", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: 'lack-of-lifeboats', (error, @alias) =>
          done error

      it 'should delete the subalias in mongo', ->
        expect(@alias.subaliases).not.to.contain name: 'deep.freeze'

    context 'a unicode name', ->
      beforeEach (done) ->
        newAlias =
          name: '💩'
          uuid: '4fac613f-fea4-49b6-8c0a-715d15d21120'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: '☃.💩'
            uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
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

        path = new iri.IRI "http://localhost:#{@serverPort}/aliases/💩?name=☃.💩"

        request.del path.toURIString(), options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: '💩', (error, @alias) =>
          done error

      it 'should delete the alias in mongo', ->
        expect(@alias.subaliases).not.to.contain name: '☃.💩'

  context 'when the alias does not exists', ->
    beforeEach (done) ->
      auth =
        username: '899801b3-e877-4c69-93db-89bd9787ceea'
        password: 'user-token'

      options =
        auth: auth
        json: true

      request.del "http://localhost:#{@serverPort}/aliases/car-over-cliff?name=keelhauled", options, (error, @response, @body) =>
        done error

    it 'should authenticate with meshblu', ->
      expect(@whoamiHandler.isDone).to.be.true

    it 'should respond with 404', ->
      expect(@response.statusCode).to.equal 404

    it 'should not return an alias', ->
      expect(@body).to.be.undefined

  context 'when a different user', ->
    context 'when the alias exists', ->
      beforeEach (done) ->
        newAlias =
          name: 'lack-of-lifeboats'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: 'leak'
            uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'd9233797-95e5-44f8-9f33-4f3af80d436d'
          password: 'other-user-token'

        options =
          auth: auth
          json: true

        request.del "http://localhost:#{@serverPort}/aliases/lack-of-lifeboats?name=leak", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 403', ->
        expect(@response.statusCode).to.equal 403

      beforeEach (done) ->
        @datastore.findOne name: 'lack-of-lifeboats', (error, @alias) =>
          done error

      it 'should not delete the record in mongo', ->
        expect(@alias.subaliases).to.contain name: 'leak', uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
