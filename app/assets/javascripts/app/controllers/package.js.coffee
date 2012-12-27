class Index extends App.Controller

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'Packages'

    App.Com.ajax(
      id:    'packages',
      type:  'GET',
      url:   '/api/packages',
      processData: true,
      success: (data) =>
        @render(data)
      )


  render: (data) ->

    for item in data.packages
      item.action = []
      if item.state == 'installed'
        item.action = ['uninstall', 'deactivate']
      else if item.state == 'uninstalled'
        item.action = ['install']
      else if item.state == 'deactivate'
        item.action = ['uninstall', 'activate']

    @html App.view('package')(
      head:     'Dashboard'
      packages: data.packages
    )


App.Config.set( 'package', Index, 'Routes' )
App.Config.set( 'Packages', { prio: 1800, parent: '#settings', name: 'Packages', target: '#package', role: ['Admin'] }, 'NavBar' )
