class Ticket extends App.ControllerTabs
  @requiredPermission: 'admin.ticket'
  header: __('Ticket')
  constructor: ->
    super

    @title('Ticket', true)
    @tabs = [
      { name: __('Base'),                target: 'base',                controller: App.SettingsArea, params: { area: 'Ticket::Base' } }
      { name: __('Number'),              target: 'number',              controller: App.SettingsArea, params: { area: 'Ticket::Number' } }
      { name: __('Auto Assignment'),     target: 'auto_assignment',     controller: App.SettingTicketAutoAssignment }
      { name: __('Article Language Detection'),  target: 'language_detection',  controller: App.SettingsArea, params: { area: 'Ticket::LanguageDetection' } }
      { name: __('Notifications'),       target: 'notification',        controller: App.SettingTicketNotifications }
      { name: __('Duplicate Detection'), target: 'duplicate_detection', controller: App.SettingTicketDuplicateDetection }
    ]
    @render()

App.Config.set('SettingTicket', { prio: 1700, parent: '#settings', name: __('Ticket'), target: '#settings/ticket', controller: Ticket, permission: ['admin.ticket'] }, 'NavBarAdmin')
