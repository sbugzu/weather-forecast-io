iconSet = "Reall"
numberOfDays = 3 # max of 8 days
numberOfAlerts = 1

# API arguments: https://darksky.net/dev/docs#forecast-request
latitude = "30.6766"
longitude = "104.0613"
apiKey = "your api key from forecast-io"
lang = "en"
units = "auto"

showForecast = 1
showForecastDescr = true
isICONForecast = true

debug = 0

command: "curl -s 'https://api.forecast.io/forecast/#{apiKey}/#{latitude},#{longitude}?exclude=minutely,hourly,flags&units=#{units}&lang=#{lang}'"

refreshFrequency: '30m'

style: """
  top: 10px
  left: 10px
  font-family: Helvetica Neue
  font-weight: bold
  text-shadow: 1px 2px 2px rgba(125, 125, 125, 0.85)
  color: #fff

  .weather
    display: flex
  .text-container
    display: flex
    flex-direction: column
    justify-content: center
  .conditions
    font-size: 20px
  .time
    font-size: 11px
    font-weight: 400
    padding-bottom: 7px
    border-bottom: 1px solid #fff
    margin-bottom: 8px
  .date
    width: 35px
    float: left
  .temp
    width: 50px
    float: left
  .desc
    float: left
  img
    height: 90px
  .forecast
    font-size: 12px
    max-width: 1000px
    .daily
      float: left
      width: 60px
      .date
      .temp
        text-align: center
        font-size: 10px
        width: 100%
      .date
        font-weight: 700
      .temp
        font-weight: 400
      .icon
        img
          padding-left: 14px
          width: 32px
          height: 32px
"""

render: -> """
  <div class="weather">
    <div class="image"></div>
    <div class="text-container">
      <div class="conditions"></div>
      <div class="time"></div>
      <div class="forecast"></div>
    </div>
  </div>
"""

tpl:
  tpl_icon_forecast: (ctx) -> """
    <div class="daily">
      <div class="date">#{ ctx.date }</div>
      <div class="icon">
        <img src='weather-forecast-io.widget/images/#{ iconSet }/#{ ctx.icon }.png' />
      </div>
      <div class="temp">#{ ctx.temp }</div>
    </div>
  """
update: (output, domEl) ->
  weatherData = JSON.parse(output)
  if debug
    console.log(weatherData)
  # image
  if weatherData.hasOwnProperty('alerts')
    $(domEl).find('.image').html('<img src=' + "weather-forecast-io.widget/images/" + iconSet + "/severe.png" + '>')
  else
    $(domEl).find('.image').html('<img src=' + "weather-forecast-io.widget/images/" + iconSet + "/" + weatherData.currently.icon + ".png"+ '>')

  # time of last update
  time = new Date(weatherData.currently.time * 1000).toLocaleDateString('en-US', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric' })
  $(domEl).find('.time').html(time)

  # current conditions
  current = weatherData.currently.summary + ", " + Math.round(weatherData.currently.temperature) + "°"
  $(domEl).find('.conditions').html(current)

  # forecast
  if showForecast == 1 || weatherData.hasOwnProperty('alerts')
    forecast = ""
    if weatherData.hasOwnProperty('alerts')
      if numberOfAlerts < weatherData.alerts.length
        maxAlerts = numberOfAlerts
      else
        maxAlerts = weatherData.alerts.length
      for i in [0..maxAlerts-1]
        forecast = forecast + "<div style='white-space: pre-wrap;'>" + weatherData.alerts[i].title + " Expires " + new Date(weatherData.alerts[i].expires * 1000).toLocaleDateString('en-US', { weekday: 'short', hour: 'numeric', minute: 'numeric' });"</div>"
        forecast = forecast + "<br>" + weatherData.alerts[i].description + "<p>"
        forecast = forecast.replace(/\n/g, " ")
        forecast = forecast.replace(/\*/g, "\n* ")
    else
      if numberOfDays > 8
        maxDays = 8
      else
        maxDays = numberOfDays
      for i in [0..numberOfDays-1]
        daily = weatherData.daily.data[i]
        date = new Date(daily.time * 1000).toLocaleDateString('en-US', {weekday: 'short'})
        temp = Math.round(daily.temperatureMax) + "° / " + Math.round(daily.temperatureMin)+ "°"
        icon = daily.icon
        if isICONForecast is true
          # ICON forecast
          ctx =
            date: date
            temp: temp
            icon: icon
          forecast += this.tpl.tpl_icon_forecast ctx
        else
          # original forecast
          summary = daily.summary
          forecastDate = "<div class=date>#{ date }</div>"
          forecastTemps = "<div class=temp>#{ temp }</div>"
          if showForecastDescr is true
            forecastDescr = "<div class=desc>#{ summary }</div><br>"
          else
            forecastDescr = "<br />"
          forecast += forecastDate + forecastTemps + forecastDescr
    forecast = forecast.replace(/ +/g, " ")
    $(domEl).find('.forecast').html(forecast)
