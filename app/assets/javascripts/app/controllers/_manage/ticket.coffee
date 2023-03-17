class Ticket extends App.ControllerTabs
  requiredPermission: 'admin.ticket'
  header: __('Ticket')
  constructor: ->
    super

    @title('Ticket', true)
    @tabs = [
      { name: __('Base'),            'target': 'base',            controller: App.SettingsArea, params: { area: 'Ticket::Base' } }
      { name: __('Number'),          'target': 'number',          controller: App.SettingsArea, params: { area: 'Ticket::Number' } }
      { name: __('Auto Assignment'), 'target': 'auto_assignment', controller: App.SettingTicketAutoAssignment }
    ]
    @render()

App.Config.set('SettingTicket', { prio: 1700, parent: '#settings', name: __('Ticket'), target: '#settings/ticket', controller: Ticket, permission: ['admin.ticket'] }, 'NavBarAdmin')
