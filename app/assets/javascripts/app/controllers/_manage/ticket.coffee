class Ticket extends App.ControllerTabs
  header: 'Ticket'
  constructor: ->
    super
    return if !@authenticate(false, 'Admin')
    @title 'Ticket', true
    @tabs = [
      { name: 'Base',   'target': 'base',   controller: App.SettingsArea, params: { area: 'Ticket::Base' } }
      { name: 'Number', 'target': 'number', controller: App.SettingsArea, params: { area: 'Ticket::Number' } }
    ]
    @render()

App.Config.set('SettingTicket', { prio: 1700, parent: '#settings', name: 'Ticket', target: '#settings/ticket', controller: Ticket, role: ['Admin'] }, 'NavBarAdmin')
