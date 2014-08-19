url   = require 'url'
Q     = require 'q'
redis = require 'redis'
Store = require './base'

module.exports = class RedisStore extends Store
  client: () ->
    unless @_client
      redisUrl = url.parse @options.redisUrl
      @_client = redis.createClient(redisUrl.port, redisUrl.hostname)

      if redisUrl.auth
        @_client.auth(redisUrl.auth.split(':')[1])
      if redisUrl.path && redisUrl.path.length >= 1
        db = parseInt redisUrl.path.replace(/^\/+/, '')
        @_client.select db unless isNaN(db)

    @_client

  prefix: () -> @options.prefix || 'geo:'
  ttl:    () -> @options.ttl || 946707779241

  key: (x) -> "#{@prefix()}#{x}"

  get: (_key) =>
    deferred = Q.defer()

    @client().get @key(_key), (err, value)->
      return deferred.reject() if err || !value

      try
        deferred.resolve JSON.parse(value)
      catch
        deferred.reject()

    return deferred.promise

  set: (_key, value) =>
    Q.ninvoke(@client(), 'setex', @key(_key), @ttl(), JSON.stringify(value))
      .then () -> value
