class Index extends App.ControllerTabs
  header: 'Trigger'
  constructor: ->
    super

    @title 'Trigger', true

    @tabs = [
      {
        name:       'Time Based',
        target:     'c-time-based',
        controller: App.TriggerTime,
      },
      {
        name:       'Event Based',
        target:     'c-event-based',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
      {
        name:       'Notifications',
        target:     'c-notification',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
      {
        name:       'Web Hooks',
        target:     'c-web-hook',
        controller: App.SettingsArea,
        params:     { area: 'Email::Base' },
      },
    ]

    @render()

App.Config.set( 'Trigger', { prio: 3000, name: 'Trigger', parent: '#manage', target: '#manage/triggers', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )

class App.TriggerTime extends App.Controller
  events:
    'click .js-new': 'new'
    #'click .js-edit': 'edit'
    'click .js-delete': 'delete'

  constructor: ->
    super
    @interval(@load, 30000)
    #@load()

  load: =>
    @ajax(
      id:   'trigger_time_index'
      type: 'GET'
      url:  @apiPath + '/jobs'
      processData: true
      success: (data, status, xhr) =>

        # load assets
        #App.Collection.loadAssets(data.assets)

        @render(data)
    )

  render: (data = {}) =>

    @html App.view('trigger/time/index')(
      triggers: []
    )


  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Channel.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  new: (e) =>
    e.preventDefault()
    channel_id = $(e.target).closest('.action').data('id')
    new App.ControllerGenericNew(
      pageData:
        object: 'Jobs'
      genericObject: 'Job'
      container: @el.closest('.content')
      callback: @load
    )
