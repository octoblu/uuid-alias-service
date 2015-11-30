http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
Server  = require '../../../src/server'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
iri = require 'iri'

describe 'PATCH /aliases/vacuum?name=moon.dust', ->
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
          name: 'vacuum'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: 'moon.dust'
            uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: '899801b3-e877-4c69-93db-89bd9787ceea'
          password: 'user-token'

        update =
          uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

        options =
          auth: auth
          json: update

        request.patch "http://localhost:#{@serverPort}/aliases/vacuum?name=moon.dust", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: 'vacuum', (error, @alias) =>
          done error

      it 'should update the alias in mongo', ->
        expect(@alias.subaliases).to.contain name: 'moon.dust', uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

    context 'a unicode name', ->
      beforeEach (done) ->
        newAlias =
          name: '💩'
          uuid: '4fac613f-fea4-49b6-8c0a-715d15d21120'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: '💩.💩'
            uuid: '5faa496d-1aa4-4ccb-b234-acac11baf389'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: '899801b3-e877-4c69-93db-89bd9787ceea'
          password: 'user-token'

        update =
          uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

        options =
          auth: auth
          json: update

        path = new iri.IRI "http://localhost:#{@serverPort}/aliases/💩?name=💩.💩"

        request.patch path.toURIString(), options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 204', ->
        expect(@response.statusCode).to.equal 204

      beforeEach (done) ->
        @datastore.findOne name: '💩', (error, @alias) =>
          done error

      it 'should update the alias in mongo', ->
        expect(@alias.subaliases).to.contain name: '💩.💩', uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

  context 'when the alias does not exists', ->
    beforeEach (done) ->
      auth =
        username: '899801b3-e877-4c69-93db-89bd9787ceea'
        password: 'user-token'

      update =
        uuid: 'a062d999-d4ef-4b83-af38-e5945b26122a'

      options =
        auth: auth
        json: update

      request.patch "http://localhost:#{@serverPort}/aliases/car-over-cliff?name=mistimed.countdown", options, (error, @response, @body) =>
        done error

    it 'should authenticate with meshblu', ->
      expect(@whoamiHandler.isDone).to.be.true

    it 'should respond with 404', ->
      expect(@response.statusCode).to.equal 404

    it 'should not return an alias', ->
      expect(@body).to.be.undefined

  context 'when the subalias does not exists', ->
    beforeEach (done) ->
      newAlias =
        name: 'car-over-cliff'
        uuid: '21560426-7338-450d-ab10-e477ef1908a6'
        owner: '899801b3-e877-4c69-93db-89bd9787ceea'
        subaliases: []

      @datastore.insert newAlias, (error, @alias) =>
        done error

    beforeEach (done) ->
      auth =
        username: '899801b3-e877-4c69-93db-89bd9787ceea'
        password: 'user-token'

      update =
        uuid: 'a062d999-d4ef-4b83-af38-e5945b26122a'

      options =
        auth: auth
        json: update

      request.patch "http://localhost:#{@serverPort}/aliases/car-over-cliff?name=mistimed.countdown", options, (error, @response, @body) =>
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
          name: 'vacuum'
          uuid: '21560426-7338-450d-ab10-e477ef1908a6'
          owner: '899801b3-e877-4c69-93db-89bd9787ceea'
          subaliases: [
            name: 'loneliness'
            uuid: '7958294f-10a8-4bed-aa7a-8c7cdfc9eadf'
          ]

        @datastore.insert newAlias, (error, @alias) =>
          done error

      beforeEach (done) ->
        auth =
          username: 'd9233797-95e5-44f8-9f33-4f3af80d436d'
          password: 'other-user-token'

        update =
          uuid: '65255089-6ed8-4a75-853a-90825a6525c3'

        options =
          auth: auth
          json: update

        request.patch "http://localhost:#{@serverPort}/aliases/vacuum?name=loneliness", options, (error, @response, @body) =>
          done error

      it 'should authenticate with meshblu', ->
        expect(@whoamiHandler.isDone).to.be.true

      it 'should respond with 403', ->
        expect(@response.statusCode).to.equal 403

      beforeEach (done) ->
        @datastore.findOne name: 'vacuum', (error, @alias) =>
          done error

      it 'should not update the alias in mongo', ->
        expect(@alias.subaliases).to.contain name: 'loneliness', uuid: '7958294f-10a8-4bed-aa7a-8c7cdfc9eadf'
