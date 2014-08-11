mmdb = require 'maxmind-db-reader'

module.extorts = class CountryDetector
  constructor: (mmdbPath, config = {}) ->
    @mmdbReader = mmdb.openSync mmdbPath
    @cookie =
      name:   config.cookieName   || 'geo'
      maxAge: config.cookieMaxAge || 946707779241

  middleware: (req, res, next) =>
    geoData = @detectByCookie req
    if geoData
      @updateRequest(req, geoData)
      next()
    else
      @detectByIp req, (geoData) =>
        if geoData
          @storeCountry(res, geoData)
          @updateRequest(req, geoData)

        next()

  detectByCookie: (req) ->
    data = req.cookies[@cookie.name]
    data = data.split '|' if data and data.length

    if data and data.length == 3
      return {
        country: data[0]
        location: {
          latitude: data[1]
          longitude: data[2]
        }
      }

  detectByIp: (req, cb) ->
    address = req.ip

    @mmdbReader.getGeoData address, (err, geoData) ->
      if geoData and geoData.country and geoData.location
        return cb({
          country: geoData.country.iso_code.toLowerCase()
          location: {
            latitude: geoData.location.latitude
            longitude: geoData.location.longitude
          }
        })

      cb(null)

  storeCountry: (res, geoData) ->
    res.cookie @cookie.name, [
      geoData.country
      geoData.location.latitude
      geoData.location.longitude
      ].join(), maxAge: @cookie.maxAge

  updateRequest: (req, geoData) ->
    req.country = geoData.country
    req.location = geoData.location

module.exports.getMiddleware = (mmdbPath, config = {}) ->
  (new CountryDetector(mmdbPath, config)).middleware
