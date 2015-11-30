AliasController = require '../controllers/alias-controller'

class Router
  constructor: ({mongoDbUri}) ->
    @aliasController = new AliasController {mongoDbUri}

  route: (app) =>
    app.post '/aliases', @aliasController.create
    app.get '/aliases/:name', @aliasController.find
    app.delete '/aliases/:name', @aliasController.delete
    app.patch '/aliases/:name', @aliasController.update

module.exports = Router
