Q = require 'q'

returnPromise = (value) -> Q.delay(0).then () -> value

module.exports = class Store
  constructor: (@options) ->
    @req = @res = undefined

  setContext: (req, res) ->
    @req = req
    @res = res

  get: (key) ->
    returnPromise undefined

  set: (key, value) ->
    returnPromise value
