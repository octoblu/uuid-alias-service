_ = require 'lodash'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
UUID_REGEX = /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/i

class AliasController
  constructor: ({mongoDbUri}) ->
    @datastore = new Datastore
      database: mongojs mongoDbUri
      collection: 'aliases'

  find: (req, res) =>
    {name} = req.params
    @datastore.findOne {name}, (error, alias) =>
      return res.send(error.messsage).status(500) if error?

      if _.isEmpty alias
        res.status(404).end()
        return

      res.status(200).send(alias)

  delete: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid
    @datastore.findOne {name}, (error, alias) =>
      return res.send(error.messsage).status(500) if error?
      if _.isEmpty alias
        res.status(404).end()
        return

      if alias.owner != owner
        res.status(403).end()
        return

      @datastore.remove {name}, (error, alias) =>
        return res.send(error.messsage).status(500) if error?
        res.status(204).end()

  update: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid
    @datastore.findOne {name}, (error, alias) =>
      return res.send(error.messsage).status(500) if error?
      if _.isEmpty alias
        res.status(404).end()
        return

      if alias.owner != owner
        res.status(403).end()
        return

      {uuid} = req.body
      update =
        $set: {uuid}

      @datastore.update {name}, update, (error, alias) =>
        return res.send(error.messsage).status(500) if error?
        res.status(204).end()

  create: (req, res) =>
    {name, uuid} = req.body
    owner = req.meshbluAuth.uuid

    if _.isEmpty(name) || _.isEmpty(uuid)
      res.status(422).end()
      return

    if UUID_REGEX.test name
      res.status(422).end()
      return

    unless UUID_REGEX.test uuid
      res.status(422).end()
      return

    @datastore.insert {name, uuid, owner}, (error) =>
      return res.send(error.messsage).status(500) if error?
      res.status(201).end()

module.exports = AliasController
