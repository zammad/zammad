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
    data =
      browser: @searchString(@dataBrowser) or "An unknown browser"
      version: @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "an unknown version"
      os:      @searchString(@dataOS) or "an unknown os"

  @check: ->
    data = @detection()

    # define min. required browser version
    map =
      Chrome2: 37
      Firefox: 32
      Explorer: 10
      Safari: 6
      Opera: 22

    # disable id older
    if data.browser && data.version
      if map[data.browser] && data.version < map[data.browser]
        @message(data, data.browser, map[data.browser])
        console.log('Browser not supported')
        return false

    # allow browser
    return true

  @message: (data, browser, version) ->
    new App.ControllerModal(
      head:     'Browser too old!'
      message:  "Your Browser is not supported (#{data.browser} #{data.version} #{data.OS}). Please use a newer one (e. g. #{browser} #{version} or higher)."
      close:    false
      backdrop: false
      keyboard: false
      shown:    true
    )

  @searchString: (data) ->
    i = 0

    while i < data.length
      dataString = data[i].string
      dataProp = data[i].prop
      @versionSearchString = data[i].versionSearch or data[i].identity
      if dataString
        return data[i].identity  unless dataString.indexOf(data[i].subString) is -1
      else return data[i].identity  if dataProp
      i++

  @searchVersion: (dataString) ->
    index = dataString.indexOf(@versionSearchString)
    return  if index is -1
    parseFloat dataString.substring(index + @versionSearchString.length + 1)

  @dataBrowser: [
    string: navigator.userAgent
    subString: "Chrome"
    identity: "Chrome"
  ,
    string: navigator.userAgent
    subString: "OmniWeb"
    versionSearch: "OmniWeb/"
    identity: "OmniWeb"
  ,
    string: navigator.vendor
    subString: "Apple"
    identity: "Safari"
    versionSearch: "Version"
  ,
    prop: window.opera
    identity: "Opera"
    versionSearch: "Version"
  ,
    string: navigator.vendor
    subString: "iCab"
    identity: "iCab"
  ,
    string: navigator.vendor
    subString: "KDE"
    identity: "Konqueror"
  ,
    string: navigator.userAgent
    subString: "Firefox"
    identity: "Firefox"
  ,
    string: navigator.vendor
    subString: "Camino"
    identity: "Camino"
  ,
    # for newer Netscapes (6+)
    string: navigator.userAgent
    subString: "Netscape"
    identity: "Netscape"
  ,
    string: navigator.userAgent
    subString: "MSIE"
    identity: "Explorer"
    versionSearch: "MSIE"
  ,
    string: navigator.userAgent
    subString: "Gecko"
    identity: "Mozilla"
    versionSearch: "rv"
  ,
    # for older Netscapes (4-)
    string: navigator.userAgent
    subString: "Mozilla"
    identity: "Netscape"
    versionSearch: "Mozilla"
  ]
  @dataOS: [
    string: navigator.platform
    subString: "Win"
    identity: "Windows"
  ,
    string: navigator.platform
    subString: "Mac"
    identity: "Mac"
  ,
    string: navigator.userAgent
    subString: "iPhone"
    identity: "iPhone/iPod"
  ,
    string: navigator.platform
    subString: "Linux"
    identity: "Linux"
  ]


