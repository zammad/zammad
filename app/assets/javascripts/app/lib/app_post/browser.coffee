class App.Browser
  @detection: ->
    data =
      browser: @searchString(@dataBrowser) or "An unknown browser"
      version: @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "an unknown version"
      os:      @searchString(@dataOS) or "an unknown os"

  @check: ->
    data = @detection()

    # disable Crome 13 and older
    if data.browser == 'Chrome' && data.version <= 13
      @message(data)
      console.log('Browser not supported')
      return false

    # disable Firefox 9 and older
    else if data.browser == 'Firefox' && data.version <= 9
      @message(data)
      console.log('Browser not supported')
      return false

    # disable IE 8 and older
    else if data.browser == 'Explorer' && data.version <= 8
      @message(data)
      console.log('Browser not supported')
      return false

    # disable Safari 3 and older
    else if data.browser == 'Safari' && data.version <= 3
      @message(data)
      console.log('Browser not supported')
      return false

    # disable Opera 10 and older
    else if data.browser == 'Opera' && data.version <= 10
      @message(data)
      console.log('Browser not supported')
      return false

    return true

  @message: (data) ->
    new App.ControllerModal(
      title:    'Browser too old!'
      message:  "Your Browser is not supported (#{data.browser} #{data.version} #{data.OS}). Please use a newer one."
      show:     true
      backdrop: false
      keyboard: false
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


