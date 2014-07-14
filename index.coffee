mmdb = require 'maxmind-db-reader'

module.extorts = class CountryDetector
  constructor: (mmdbPath, config = {}) ->
    @mmdbReader = mmdb.openSync mmdbPath
    @cookie =
      name:   config.cookieName   || 'country'
      maxAge: config.cookieMaxAge || 946707779241
    @defaultCountry = config.defaultCountry || null

  middleware: (req, res, next) =>
    country = @detectByCookie req
    if country
      @updateRequest(req, country)
      next()
    else
      @detectByIp req, (country) =>
        @storeCountry(res, country) if country
        @updateRequest(req, country)
        next()

  detectByCookie: (req) ->
    req.cookies[@cookie.name]

  detectByIp: (req, cb) ->
    address = req.ip

    @mmdbReader.getGeoData address, (err, geoData) ->
      if geoData and geoData.country
        return cb(geoData.country.iso_code.toLowerCase())

      cb(null)

  storeCountry: (res, country) ->
    res.cookie @cookie.name, country, maxAge: @cookie.maxAge

  updateRequest: (req, country) ->
    req.country = country || @defaultCountry

module.exports.getMiddleware = (mmdbPath, config = {}) ->
  (new CountryDetector(mmdbPath, config)).middleware
