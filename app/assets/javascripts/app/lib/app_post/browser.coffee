class App.Browser extends App.Controller
  constructor: ->
    super

  @init: ->
    @browser = @searchString(@dataBrowser) or "An unknown browser"
    @version = @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "an unknown version"
    @OS = @searchString(@dataOS) or "an unknown OS"
    return @check()


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

  @check: ->
    if @browser == 'Chrome' && @version <= 27
      App.Event.trigger('session:browscheckfailed', {title: 'Error', message: 'Your Browser is not supported!'})
      return false
    else
      return true

      


