class Index extends App.ControllerSubContent
  requiredPermission: 'admin.webhook'
  header: 'Webhooks'
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'Webhook'
      defaultSortBy: 'name'
      pageData:
        home: 'webhooks'
        object: 'Webhook'
        objects: 'Webhooks'
        pagerAjax: true
        pagerBaseUrl: '#manage/webhook/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#webhooks'
        notes: [
          'Webhooks are ...'
        ]
        buttons: [
          { name: 'Example Payload', 'data-type': 'payload', class: 'btn' }
          { name: 'New Webhook', 'data-type': 'new', class: 'btn--success' }
        ]
        logFacility: 'webhook'
      payloadExampleUrl: '/api/v1/webhooks/preview'
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate( @page || 1 )

App.Config.set('Webhook', { prio: 3350, name: 'Webhook', parent: '#manage', target: '#manage/webhook', controller: Index, permission: ['admin.webhook'] }, 'NavBarAdmin')
