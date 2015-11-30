_ = require 'lodash'
AliasService = require '../services/alias-service'
SubAliasService = require '../services/sub-alias-service'

class AliasController
  constructor: ({mongoDbUri}) ->
    @aliasService = new AliasService {mongoDbUri}
    @subAliasService = new SubAliasService {mongoDbUri}

  find: (req, res) =>
    {name} = req.params
    @aliasService.find {name}, (error, alias) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(200).send(alias)

  delete: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid
    @aliasService.delete {name,owner}, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(204).end()

  update: (req, res) =>
    {name} = req.params
    owner = req.meshbluAuth.uuid
    @aliasService.update {name,owner}, uuid: req.body.uuid, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.messsage if error?
      res.status(204).end()

  create: (req, res) =>
    {name, uuid} = req.body
    owner = req.meshbluAuth.uuid

    @aliasService.create {name, uuid, owner}, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(201).end()

  createSubAlias: (req, res) =>
    {alias} = req.params
    {name, uuid} = req.body
    owner = req.meshbluAuth.uuid

    @subAliasService.create {alias, name, uuid, owner}, (error) =>
      return res.status(error.status).send error.messsage if error?.status?
      return res.status(500).send error.message if error?
      res.status(201).end()

module.exports = AliasController
