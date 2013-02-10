class Index extends App.ControllerLevel2
  toggleable: false
#  toggleable: true

  constructor: ->
    super

    return if !@authenticate()

    # system
    if @type is 'system'
      @menu = [
        { name: 'Base',     'target': 'base',      controller: App.SettingsArea, params: { area: 'System::Base' } },
    #    { name: 'Language', 'target': 'language',  controller: App.SettingsSystem, params: { area: 'System::Language' } },
    #    { name: 'Log',      'target': 'log',       controller: App.SettingsSystem, params: { area: 'System::Log' } },
        { name: 'Storage',  'target': 'storage',   controller: App.SettingsArea, params: { area: 'System::Storage' } },
      ]
      @page = {
        title:     'System',
        head:      'System',
        sub_title: 'Settings'
        nav:       '#settings/system',
      }

    # security
    if @type is 'security'
      @menu = [
        { name: 'Base',                     'target': 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } },
#        { name: 'Authentication',           'target': 'auth',             controller: App.SettingsArea, params: { area: 'Security::Authentication' } },
        { name: 'Password',                 'target': 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } },
        { name: 'Third-Party Applications', 'target': 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } },
#        { name: 'Session',        'target': 'session',   controller: '' },
      ] 
      @page = {
        title:     'Security',
        head:      'Security',
        sub_title: 'Settings'
        nav:       '#settings/security',
      }

    # import
    if @type is 'import'
      @menu = [
        { name: 'Base',           'target': 'base',          controller: App.SettingsArea, params: { area: 'Import::Base' } },
        { name: 'OTRS',           'target': 'otrs',          controller: App.SettingsArea, params: { area: 'Import::OTRS' } },
      ] 
      @page = {
        title:     'Import',
        head:      'Import',
        sub_title: 'System'
        nav:       '#settings/import',
      }

    # ticket
    if @type is 'ticket'
      @menu = [
        { name: 'Base',           'target': 'base',          controller: App.SettingsArea, params: { area: 'Ticket::Base' } },
        { name: 'Number',         'target': 'number',        controller: App.SettingsArea, params: { area: 'Ticket::Number' } },
#        { name: 'Sender Format',  'target': 'sender-format', controller: App.SettingsArea, params: { area: 'Ticket::SenderFormat' } },
      ] 
      @page = {
        title:     'Ticket',
        head:      'Ticket',
        sub_title: 'Settings'
        nav:       '#settings/ticket',
      }

    # render page
    @render()

App.Config.set( 'settings/:type/:target', Index, 'Routes' )
App.Config.set( 'settings/:type', Index, 'Routes' )

App.Config.set( 'System', { prio: 1400, parent: '#settings', name: 'System', target: '#settings/system', role: ['Admin'] }, 'NavBar' )
App.Config.set( 'Security', { prio: 1500, parent: '#settings', name: 'Security', target: '#settings/security', role: ['Admin'] }, 'NavBar' )
App.Config.set( 'Import', { prio: 1550, parent: '#settings', name: 'Import', target: '#settings/import', role: ['Admin'] }, 'NavBar' )
App.Config.set( 'Ticket', { prio: 1600, parent: '#settings', name: 'Ticket', target: '#settings/ticket', role: ['Admin'] }, 'NavBar' )
App.Config.set( 'Object', { prio: 1700, parent: '#settings', name: 'Objects', target: '#settings/objects', role: ['Admin'] }, 'NavBar' )
