class Widget
  constructor: ->
    return if !App.Config.get('developer_mode')
    return if App.Log.config('banner') is false
    banner = """
|
| Welcome Zammad Developer!
| You can enable debugging by the following examples (value is a regex):
|
| App.Log.config('module', 'i18n|websocket') // enable debugging for i18n and websocket class
| App.Log.config('content', 'send')          // enable debugging for messages which contains the string 'send'
| App.Log.config('banner', false)            // disable this banner
|
| App.Log.config()         // current settings
| App.Log.config('banner') // current setting for banner
|
"""
    console.log(banner)

App.Config.set( 'dev_banner', Widget, 'Widgets' )
