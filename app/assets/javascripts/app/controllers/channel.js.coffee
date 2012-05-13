$ = jQuery.sub()

class Index extends App.ControllerLevel2
#  toggleable: true
  toggleable: false

  menu: [
    { name: 'Web',      target: 'web',      controller: App.ChannelWeb },
    { name: 'Mail',     target: 'email',    controller: App.ChannelEmail },
    { name: 'Chat',     target: 'chat',     controller: App.ChannelChat },
    { name: 'Twitter',  target: 'twitter',  controller: App.ChannelTwitter },
    { name: 'Facebook', target: 'facebook', controller: App.ChannelFacebook },
  ] 
  page: {
    title:     'Channels',
    head:      'Channels',
    sub_title: 'Management'
    nav:       '#channels',
  }

  constructor: ->
    super

    return if !@authenticate()

    # render page
    @render()

Config.Routes['channels/:target'] = Index
Config.Routes['channels'] = Index

