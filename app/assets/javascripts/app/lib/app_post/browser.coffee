###

check if browser is supported

  result = App.Browser.check()

  result = true # true/false

get used browser

  browser = App.Browser.detection()

  browser = {
    browser: "Chrome",
    version: 37,
    OS:      "Mac"
  }

###

class App.Browser
  @detection: ->
    parser = new UAParser()
    data =
      browser: parser.getBrowser()
      device: parser.getDevice()
      os: parser.getOS()

  @check: ->
    data = @detection()

    # define min. required browser version
    map =
      Chrome: 37
      Firefox: 31
      Explorer: 10
      Safari: 6
      Opera: 22

    # disable id older
    if data.browser
      if map[data.browser.name] && data.browser.major < map[data.browser.name]
        @message(data, map[data.browser.name])
        console.log('Browser not supported')
        return false

    # allow browser
    true

  @fingerprint: ->
    localStorage = window['localStorage']

    # read from local storage
    if localStorage
      fingerprint = localStorage.getItem('fingerprint')
    return fingerprint if fingerprint

    # detect fingerprint
    data = @detection()
    resolution = "#{window.screen.availWidth}x#{window.screen.availHeight}/#{window.screen.pixelDepth}"
    timezone = new Date().toString().match(/\s\(.+?\)$/)
    hashCode = (s) ->
      s.split('').reduce(
        (a,b) ->
          a=((a<<5)-a)+b.charCodeAt(0)
          a&a
        0
      )
    fingerprint = hashCode("#{data.browser.name}#{data.browser.major}#{data.os}#{resolution}#{timezone}")

    # write to local storage
    if localStorage
      localStorage.setItem('fingerprint', fingerprint)
    fingerprint

  @message: (data, version) ->
    new App.ControllerModal(
      head:     'Browser too old!'
      message:  "Your Browser is not supported (#{data.browser.name} #{data.browser.major} on #{data.os.name}). Please use a newer one (e. g. #{data.browser.name} #{version} or higher)."
      close:    false
      backdrop: false
      keyboard: false
      shown:    true
    )
