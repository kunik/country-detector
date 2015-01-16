Q      = require 'q'
mmdb   = require 'maxmind-db-reader'
geoip2 = require 'geoip2ws'
utils  = require './utils'

module.extorts = class CountryDetector
  constructor: (mmdbPath, config = {}) ->
    @mmdbReader = mmdb.openSync mmdbPath

    sorePath = "./store/#{config.store || 'cookie'}"
    Store = require(sorePath)
    @store  = new Store(config.storeOptions)

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
    ip = req.ip# = '46.164.156.82'

    @store.setContext(req, res)
    @store.get ip
      .then (geoData) -> utils.formatGeoData geoData
      .fail () =>
        @detectByIp ip
          .then (geoData) => @store.set(ip, geoData)
      .fail (geoData) -> geoData
      .then (geoData) ->
        if geoData
          req.country  = geoData.country
          req.location = geoData.location
      .fin next

  detectByIp: (ip, cb) =>
    # if ip == '127.0.0.1'
    #   deferred = Q.defer()
    #   process.nextTick ()->
    #     deferred.reject(utils.formatGeoData null)
    #   return deferred.promise

    Q.ninvoke(@mmdbReader, 'getGeoData', ip)
      .then (_geoData) -> utils.formatGeoData _geoData
      .fail () -> utils.formatGeoData null
      .then (geoData) =>
        if @geoip2ws.call and geoData.precision < 3
          Q.ninvoke(@geoip2ws, 'call', ip)
            .then (_geoData) ->
              if _geoData.location
                utils.formatGeoData _geoData
              else
                geoData
            .fail () -> geoData
        else
          geoData

module.exports.getMiddleware = (mmdbPath, config = {}) ->
  (new CountryDetector(mmdbPath, config)).middleware
