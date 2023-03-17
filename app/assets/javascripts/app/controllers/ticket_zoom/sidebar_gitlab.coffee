class SidebarGitLab extends App.SidebarGitIssue
  provider: 'GitLab'
  urlPlaceholder: 'https://git.example.com/group1/project1/-/issues/1'

App.Config.set('500-GitLab', SidebarGitLab, 'TicketCreateSidebar')
App.Config.set('500-GitLab', SidebarGitLab, 'TicketZoomSidebar')
