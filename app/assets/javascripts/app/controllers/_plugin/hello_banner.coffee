class HelloBanner
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
| Visit %chttp://zammad.com/jobs%c to learn about our current job openings.
|
| Your Zammad Team
|
"""
    console.log(banner, 'text-decoration: underline;', 'text-decoration: none;')

App.Config.set('hello_banner', HelloBanner, 'Plugins')
