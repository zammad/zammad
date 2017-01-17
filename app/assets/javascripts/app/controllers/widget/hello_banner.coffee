class Widget
  constructor: ->
    return if App.Config.get('developer_mode')
    banner = """
|  _____                                    _
| / _  / __ _ _ __ ___  _ __ ___   __ _  __| |
| \\// / / _` | '_ ` _ \\| '_ ` _ \\ / _` |/ _` |
|  / //\\ (_| | | | | | | | | | | | (_| | (_| |
| /____/\\__,_|_| |_| |_|_| |_| |_|\\__,_|\\__,_|
|
| Hi there, nice to meet you!
|
| Visit %chttps://zammad.org/participate%c and let's make Zammad better.
|
| The Zammad Team.
|
"""
    console.log(banner, 'text-decoration: underline;', 'text-decoration: none;')

App.Config.set('hello_banner', Widget, 'Widgets')
