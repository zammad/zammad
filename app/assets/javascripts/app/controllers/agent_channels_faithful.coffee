# Faithful agent Channels panel — matches docs/ui-references/agent-console/
# (ChannelsPanel in agent-manage.jsx).
class App.AgentChannelsFaithful extends App.Controller
  @requiredPermission: ['admin.channel_web', 'admin.channel_formular', 'admin.channel_email', 'admin.channel_sms', 'admin.channel_chat']

  events:
    'click .js-section': 'onSectionClick'
    'click .js-card':    'onCardClick'

  constructor: (params) ->
    super
    @title __('Channels'), true
    @navupdate '#channels'
    @render()

  release: => super

  onSectionClick: (e) =>
    e.preventDefault()
    target = $(e.currentTarget).data('section')
    return if !target
    @navigate target

  onCardClick: (e) =>
    href = $(e.currentTarget).data('href')
    @navigate href if href

  sections: ->
    [
      { key: 'web',   label: 'Web',   href: '#channels/web',   active: true }
      { key: 'form',  label: 'Form',  href: '#channels/form' }
      { key: 'email', label: 'Email', href: '#channels/email' }
      { key: 'sms',   label: 'SMS',   href: '#channels/sms' }
      { key: 'chat',  label: 'Chat',  href: '#channels/chat' }
    ]

  # Channel cards mirror the wireframe. Connected/Off is best-effort —
  # for an MVP-faithful render we show 'Connected' for channels Zammad
  # ships configured by default (web, email, chat) and 'Off' for the rest.
  channels: ->
    [
      { key: 'web',   icon: 'dashboard', label: 'Web widget',  on: true,  desc: 'Embed a help widget on any page',  href: '#channels/web' }
      { key: 'form',  icon: 'dashboard', label: 'Form',        on: false, desc: 'Drop a ticket form into your site', href: '#channels/form' }
      { key: 'email', icon: 'inbox',     label: 'Email',       on: true,  desc: 'Inbound + outbound email channels', href: '#channels/email' }
      { key: 'sms',   icon: 'dashboard', label: 'SMS',         on: false, desc: 'Tickets from text messages',        href: '#channels/sms' }
      { key: 'chat',  icon: 'tickets',   label: 'Live chat',   on: true,  desc: 'Real-time chat with customers',     href: '#channels/chat' }
    ]

  render: =>
    @html App.view('agent_channels_faithful')(
      sections: @sections()
      channels: @channels()
    )

App.Config.set('AgentChannelsFaithful', { controller: 'AgentChannelsFaithful', permission: ['admin.channel_web', 'admin.channel_formular', 'admin.channel_email', 'admin.channel_sms', 'admin.channel_chat'] }, 'permanentTask')
