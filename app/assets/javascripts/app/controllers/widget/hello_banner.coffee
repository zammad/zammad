class Widget
  constructor: ->
    return if App.Config.get('developer_mode')
    banner = """

| Hi there, nice to meet you!
|
"""
    console.log(banner, 'text-decoration: underline;', 'text-decoration: none;')

App.Config.set('hello_banner', Widget, 'Widgets')
