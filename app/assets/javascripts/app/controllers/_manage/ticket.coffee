class Ticket extends App.ControllerTabs
  requiredPermission: 'admin.ticket'
  header: 'Ticket'
  constructor: ->
    super

    @title('Ticket', true)
    @tabs = [
      { name: 'Base',            'target': 'base',            controller: App.SettingsArea, params: { area: 'Ticket::Base' } }
      { name: 'Number',          'target': 'number',          controller: App.SettingsArea, params: { area: 'Ticket::Number' } }
      { name: 'Auto Assignment', 'target': 'auto_assignment', controller: App.SettingTicketAutoAssignment }
    ]
    @render()

App.Config.set('SettingTicket', { prio: 1700, parent: '#settings', name: 'Ticket', target: '#settings/ticket', controller: Ticket, permission: ['admin.ticket'] }, 'NavBarAdmin')
