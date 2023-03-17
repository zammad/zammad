class SidebarGitHub extends App.SidebarGitIssue
  provider: 'GitHub'
  urlPlaceholder: 'https://github.com/organization/repository/issues/42'

App.Config.set('500-GitHub', SidebarGitHub, 'TicketCreateSidebar')
App.Config.set('500-GitHub', SidebarGitHub, 'TicketZoomSidebar')
