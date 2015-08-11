class FFlt35
  constructor: ->
    data = App.Browser.detection()
    if data.browser.name is 'Firefox' && data.browser.major && data.browser.major < 35

      # for firefox lower 35 we need to set a class to hide own dropdown images
      # whole file can be removed after dropping firefox 34 and lower support
      $('html').addClass('ff-lt-35')

App.Config.set( 'aaa_ff-lt-35', FFlt35, 'Widgets' )