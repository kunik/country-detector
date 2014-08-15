mmdb      = require 'maxmind-db-reader'
geoip2    = require 'geoip2ws'
precesion = (x) -> String(x).replace('.', '').length - x.toFixed().length

module.extorts = class CountryDetector
  constructor: (mmdbPath, config = {}) ->
    @mmdbReader = mmdb.openSync mmdbPath
    @cookie =
      name:   config.cookieName   || 'geo'
      maxAge: config.cookieMaxAge || 946707779241
    @geoip2ws =
      userId:     config.geoip2ws && config.geoip2ws.userId
      licenseKey: config.geoip2ws && config.geoip2ws.licenseKey
      type:      (config.geoip2ws && config.geoip2ws.type) || 'city'

    if @geoip2ws.licenseKey
      @geoip2ws.call = geoip2(
        @geoip2ws.userId,
        @geoip2ws.licenseKey,
        @geoip2ws.type)

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
          latitude: parseFloat data[1]
          longitude: parseFloat data[2]
        }
      }

  detectByIp: (req, cb) ->
    address = req.ip
    return cb(null) if address == '127.0.0.1'

    @mmdbReader.getGeoData address, (err, geoData) =>
      result = {
        country: null
        location: { latitude: 0, longitude: 0 }
      }

      if geoData and geoData.country and geoData.location
        result.country = geoData.country.iso_code.toLowerCase()
        result.location.latitude = geoData.location.latitude
        result.location.longitude = geoData.location.longitude

      if @geoip2ws.call and precesion(result.location.latitude) < 3
        @geoip2ws.call address, (err, geoData) ->
          result.country = geoData.country.iso_code.toLowerCase()
          result.location.latitude = geoData.location.latitude
          result.location.longitude = geoData.location.longitude
          cb result

      else if result.country
        cb result
      else
        cb null

  storeCountry: (res, geoData) ->
    res.cookie @cookie.name, [
      geoData.country
      geoData.location.latitude
      geoData.location.longitude
      ].join('|'), maxAge: @cookie.maxAge

  updateRequest: (req, geoData) ->
    req.country = geoData.country
    req.location = geoData.location

module.exports.getMiddleware = (mmdbPath, config = {}) ->
  (new CountryDetector(mmdbPath, config)).middleware
