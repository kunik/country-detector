module.exports = utils =
  precision: (latitude, longitude) ->
    [x, y] = [latitude, longitude]

    Math.max(
      String(x).replace('.', '').length - x.toFixed().length,
      String(y).replace('.', '').length - y.toFixed().length
    )

  formatGeoData: (geoData) ->
    result = { location: {} }

    if geoData and geoData.country and geoData.location
      if geoData.country.iso_code
        result.country = geoData.country.iso_code.toLowerCase()
      else
        result.country = geoData.country

      result.location.latitude  = x = geoData.location.latitude
      result.location.longitude = y = geoData.location.longitude

      result.precision = utils.precision(x, y)

    return result
