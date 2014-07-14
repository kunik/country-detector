# Installation

```
npm install country-detector
```

# Usage

```
app.use countryDetector.getMiddleware('./GeoLite2-City.mmdb', {
  cookieName: 'country'
  cookieMaxAge: 946707779241
  })

...

console.log(req.country)
```
