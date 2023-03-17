class DevBanner
  constructor: ->
    return if !App.Config.get('developer_mode')
    return if App.Log.config('banner') is false
    banner = """
|
| Welcome Zammad Developer!
| You can enable debugging with the following examples (value is a regex):
|
| App.Log.config('module', '(websocket|delay|interval)') // enable debugging for websocket, delay and interval class
| App.Log.config('content', 'send')                      // enable debugging for messages which contain the string 'send'
| App.Log.config('banner', false)                        // disable this banner
|
| App.Log.config()         // current settings
| App.Log.config('banner') // current setting for banner
|
"""
    console.log(banner)

App.Config.set('dev_banner', DevBanner, 'Plugins')
