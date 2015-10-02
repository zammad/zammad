class App.ChannelChat extends App.ControllerTabs
  header: 'Chat'
  constructor: ->
    super

    @title 'Chat', true

    @tabs = [
      {
        name:       'Settings',
        target:     'setting',
        controller: App.SettingsArea, params: { area: 'Chat::Base' },
      },
    ]

    @render()

# enable/disable

# show also if nobody is online / leave a message

# channels
 # sales - en / authentication needed
 # sales - de / authentication needed



# agent
 # channes I'm work for

 # x sales - de / greeting
 # o sales - en / greeting

# concurent chats

# active chats
 # name, email, location/ip, age


# chat history

App.Config.set( 'Chat', { prio: 4000, name: 'Chat', parent: '#channels', target: '#channels/chat', controller: App.ChannelChat, role: ['Admin'] }, 'NavBarAdmin' )
