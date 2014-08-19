Q     = require 'q'
Store = require './base'

module.exports = class CookieStore extends Store
  cookieName: () -> @options.cookieName   || 'geo'
  maxAge:     () -> @options.cookieMaxAge || 946707779241
  
  get: (key) =>
    data = @req.cookies["#{@cookieName()}-#{key}"]
    data = data.split '|' if data and data.length
    deferred = Q.defer()

    process.nextTick () ->
      if data and data.length == 3
        [country, latitude, longitude] = data

        deferred.resolve {
          country: country
          location:
            latitude: parseFloat latitude
            longitude: parseFloat longitude
        }
      else
        deferred.reject()

    deferred.promise

  set: (key, value) =>
    @res.cookie "#{@cookieName()}-#{key}", [
      value.country
      value.location.latitude
      value.location.longitude
      ].join('|'), maxAge: @maxAge()

    Q.delay(0).then () -> value
