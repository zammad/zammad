class Index extends App.Controller

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    App.Com.ajax(
      id:    'packages',
      type:  'GET',
      url:   '/api/packages',
      processData: true,
      success: (data) =>
        @render(data)
      )


  render: (data) ->

    @html App.view('package')(
      head:     'Dashboard'
      packages: data.packages
    )


App.Config.set( 'package', Index, 'Routes' )
App.Config.set( 'Packages', { prio: 1800, parent: '#settings', name: 'Packages', target: '#package', role: ['Admin'] }, 'NavBar' )
