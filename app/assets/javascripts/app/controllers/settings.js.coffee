class Branding extends App.ControllerTabs
  constructor: ->
    super
    return if !@authenticate()
    @title 'Branding', true
    @tabs = [
      { name: 'Base',         'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Branding' } },
    ]
    @render()

class System extends App.ControllerTabs
  constructor: ->
    super
    return if !@authenticate()
    @title 'System', true
    @tabs = [
      { name: 'Base',         'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Base' } },
      { name: 'Storage',      'target': 'storage',  controller: App.SettingsArea, params: { area: 'System::Storage' } },
      { name: 'Geo Services', 'target': 'geo',      controller: App.SettingsArea, params: { area: 'System::Geo' } },
      { name: 'Frontend',     'target': 'ui',       controller: App.SettingsArea, params: { area: 'System::UI' } },
    ]
    @render()

class Security extends App.ControllerTabs
  constructor: ->
    super
    return if !@authenticate()
    @title 'Security', true
    @tabs = [
      { name: 'Base',                     'target': 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } },
#       { name: 'Authentication',           'target': 'auth',             controller: App.SettingsArea, params: { area: 'Security::Authentication' } },
      { name: 'Password',                 'target': 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } },
      { name: 'Third-Party Applications', 'target': 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } },
#       { name: 'Session',        'target': 'session',   controller: '' },
    ]
    @render()

class Import extends App.ControllerTabs
  constructor: ->
    super
    return if !@authenticate()
    @title 'Import', true
    @tabs = [
      { name: 'Base',         'target': 'base',     controller: App.SettingsArea, params: { area: 'Import::Base' } },
      { name: 'OTRS',         'target': 'otrs',     controller: App.SettingsArea, params: { area: 'Import::OTRS' } },
    ]
    @render()

class Ticket extends App.ControllerTabs
  constructor: ->
    super
    return if !@authenticate()
    @title 'Ticket', true
    @tabs = [
      { name: 'Base',           'target': 'base',          controller: App.SettingsArea, params: { area: 'Ticket::Base' } },
      { name: 'Number',         'target': 'number',        controller: App.SettingsArea, params: { area: 'Ticket::Number' } },
#      { name: 'Sender Format',  'target': 'sender-format', controller: App.SettingsArea, params: { area: 'Ticket::SenderFormat' } },
    ]
    @render()

App.Config.set( 'SettingBranding',  { prio: 1200, parent: '#settings', name: 'Branding', target: '#settings/branding', controller: Branding, role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'SettingSystem',    { prio: 1400, parent: '#settings', name: 'System',   target: '#settings/system', controller: System, role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'SettingSecurity',  { prio: 1500, parent: '#settings', name: 'Security', target: '#settings/security', controller: Security, role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'SettingImport',    { prio: 1550, parent: '#settings', name: 'Import',   target: '#settings/import', controller: Import, role: ['Admin'] }, 'NavBarAdmin' )
App.Config.set( 'SettingTicket',    { prio: 1600, parent: '#settings', name: 'Ticket',   target: '#settings/ticket', controller: Ticket, role: ['Admin'] }, 'NavBarAdmin' )

