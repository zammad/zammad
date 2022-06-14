###

check if browser is supported

  result = App.Browser.check()

  result = true # true/false

get used browser

  browser = App.Browser.detection()

  browser = {
    browser: {
      major: "48",
      name: "Chrome",
      version: "48.0.2564.109",
    },
    os: {
      name: "Mac OS",
      version: "10.11.3",
    }
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
      Firefox:  78  # ESR
      Chrome:   83  # parallel to FF ESR - Edge is also detected as Chrome
      Opera:    69  # based on Chrome 83
      Explorer: 11  # 10 is EOL
      Safari:   11  # released 2018

    # disable id older
    if data.browser
      if map[data.browser.name] && data.browser.major < map[data.browser.name]
        new Modal(
          data: data
          version: map[data.browser.name]
        )
        App.Log.error('Browser', 'Browser not supported')
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

  @magicKey: ->
    if @isMac()
      'cmd'
    else
      'ctrl'

  @hotkeys: ->
    if @isMac()
      'alt+ctrl'
    else
      'ctrl+shift'

  @isMac: ->
    browser = @detection()

    osName = browser?.os?.name?.toString()

    return if !osName

    osName.match(/mac/i)

class Modal extends App.ControllerModal
  buttonClose: false
  buttonCancel: false
  buttonSubmit: false
  backdrop: false
  keyboard: false
  head: __('Outdated Browser')

  content: ->
    "Your Browser is not supported (#{@data.browser.name} #{@data.browser.major} on #{@data.os.name}). Please use a newer one (e. g. #{@data.browser.name} #{@version} or higher)."
