_ = require 'lodash'
mongojs = require 'mongojs'
Datastore = require 'meshblu-core-datastore'
http = require 'http'
UUID_REGEX = /[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/i

class SubAliasService
  constructor: ({mongoDbUri}) ->
    @datastore = new Datastore
      database: mongojs mongoDbUri
      collection: 'aliases'

  create: ({alias,name,uuid,owner}, callback) =>
    return callback @userError 422 unless @_valid {name,uuid,owner}

    @datastore.findOne name: alias, (error, response) =>
      return callback error if error?
      return callback @userError 404, http.STATUS_CODES[404] if _.isEmpty response
      return callback @userError 403, http.STATUS_CODES[403] unless response.owner == owner

      update =
        $addToSet:
          subaliases:
            name: name
            uuid: uuid

      @datastore.update name: alias, update, (error, response) =>
        return callback error if error?
        callback()

  userError: (status, message) =>
    error = new Error message
    error.status = status
    error

  _valid: ({name,uuid,owner}) =>
    return false if _.isEmpty name
    return false if _.isEmpty uuid
    return false if UUID_REGEX.test name
    return false unless UUID_REGEX.test uuid
    true

module.exports = SubAliasService
