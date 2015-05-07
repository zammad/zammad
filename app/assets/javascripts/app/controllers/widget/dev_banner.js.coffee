class Widget
  constructor: ->
    return if App.Config.get('developer_mode')
    banner = """
|                                                _
|  _____                                       __(_)
| /__  /  ____ _____ ___  ____ ___  ____ _____/ /
|   / /  / __ `/ __ `__ \\/ __ `__ \\/ __ `/ __  /
|  / /__/ /_/ / / / / / / / / / / / /_/ / /_/ /
| /____/\\__,_/_/ /_/ /_/_/ /_/ /_/\\__,_/\\__,_/
|
| Hi there, nice to meet you!
|
| Visit %chttp://zammad.com/jobs%c to learn about our current job openings.
|
| Your Zammad Team!
|
"""
    console.log(banner, "text-decoration: underline;", "text-decoration: none;")

App.Config.set( 'dev_banner', Widget, 'Widgets' )
