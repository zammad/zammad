class Branding extends App.ControllerTabs
  header: 'Branding'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Branding', true
    @tabs = [
      { name: 'Base',       'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Branding' } }
    ]
    @render()

class System extends App.ControllerTabs
  header: 'System'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'System', true
    @tabs = []
    if !App.Config.get('system_online_service')
      @tabs.push { name: 'Base',       'target': 'base',     controller: App.SettingsArea, params: { area: 'System::Base' } }
    @tabs.push { name: 'Services',   'target': 'services', controller: App.SettingsArea, params: { area: 'System::Services' } }
    if !App.Config.get('system_online_service')
      @tabs.push { name: 'Storage',    'target': 'storage',  controller: App.SettingsArea, params: { area: 'System::Storage' } }
    @tabs.push { name: 'Frontend',   'target': 'ui',       controller: App.SettingsArea, params: { area: 'System::UI' } }
    @render()

class Security extends App.ControllerTabs
  header: 'Security'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Security', true
    @tabs = [
      { name: 'Base',                     'target': 'base',             controller: App.SettingsArea, params: { area: 'Security::Base' } }
#       { name: 'Authentication',           'target': 'auth',             controller: App.SettingsArea, params: { area: 'Security::Authentication' } }
      { name: 'Password',                 'target': 'password',         controller: App.SettingsArea, params: { area: 'Security::Password' } }
      { name: 'Third-Party Applications', 'target': 'third_party_auth', controller: App.SettingsArea, params: { area: 'Security::ThirdPartyAuthentication' } }
    ]
    @render()

class Import extends App.ControllerTabs
  header: 'Import'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Import', true
    @tabs = [
      { name: 'Base',         'target': 'base',     controller: App.SettingsArea, params: { area: 'Import::Base' } }
      { name: 'OTRS',         'target': 'otrs',     controller: App.SettingsArea, params: { area: 'Import::OTRS' } }
    ]
    @render()

class Ticket extends App.ControllerTabs
  header: 'Ticket'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Ticket', true
    @tabs = [
      { name: 'Base',         'target': 'base',     controller: App.SettingsArea, params: { area: 'Ticket::Base' } }
      { name: 'Number',       'target': 'number',   controller: App.SettingsArea, params: { area: 'Ticket::Number' } }
    ]
    @render()

App.Config.set('SettingBranding',  { prio: 1200, parent: '#settings', name: 'Branding', target: '#settings/branding', controller: Branding, role: ['Admin'] }, 'NavBarAdmin')
App.Config.set('SettingSystem',    { prio: 1400, parent: '#settings', name: 'System',   target: '#settings/system',   controller: System,   role: ['Admin'] }, 'NavBarAdmin')
App.Config.set('SettingSecurity',  { prio: 1600, parent: '#settings', name: 'Security', target: '#settings/security', controller: Security, role: ['Admin'] }, 'NavBarAdmin')
App.Config.set('SettingTicket',    { prio: 1700, parent: '#settings', name: 'Ticket',   target: '#settings/ticket',   controller: Ticket,   role: ['Admin'] }, 'NavBarAdmin')
App.Config.set('SettingImport',    { prio: 1800, parent: '#settings', name: 'Import',   target: '#settings/import',   controller: Import,   role: ['Admin'] }, 'NavBarAdmin')
