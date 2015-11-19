class Index extends App.ControllerContent
  events:
    'click .js-new':         'new'
    'click .js-edit':        'edit'
    'click .js-delete':      'delete'

  constructor: ->
    super

    # check authentication
    return if !@authenticate()

    @render()

    #@interval(@load, 60000)
    #@load()

  load: =>
    # @startLoading()
    # @ajax(
    #   id:   'twitter_index'
    #   type: 'GET'
    #   url:  @apiPath + '/twitter'
    #   processData: true
    #   success: (data, status, xhr) =>
    #     App.Collection.loadAssets(data.assets)
    #     @stopLoading()
    #     @render(data)
    # )

  render: =>
    # accounts = App.Twitter.search(
    #   sortBy: 'name'
    # )

    # # show description button, only if content exists
    # showDescription = false
    # if App.Twitter.description
    #   if !_.isEmpty(accounts)
    #     showDescription = true
    #   else
    #     description = marked(App.Twitter.description)

    @html App.view('twitter/index')()
      # accounts: accounts
      # showDescription: showDescription
      # description:     description

  new: (e) ->
  #   e.preventDefault()
  #   new App.ControllerGenericNew(
  #     pageData:
  #       title: 'SLAs'
  #       object: 'Sla'
  #       objects: 'SLAs'
  #     genericObject: 'Sla'
  #     container:     @el.closest('.content')
  #     callback:      @load
  #     large:         true
  #   )

  edit: (e) ->
  #   e.preventDefault()
  #   id = $(e.target).closest('.action').data('id')
  #   new App.ControllerGenericEdit(
  #     id: id
  #     pageData:
  #       title: 'SLAs'
  #       object: 'Sla'
  #       objects: 'SLAs'
  #     genericObject: 'Sla'
  #     callback:      @load
  #     container:     @el.closest('.content')
  #     large:         true
  #   )

  delete: (e) =>
  #   e.preventDefault()
  #   id   = $(e.target).closest('.action').data('id')
  #   item = App.Twitter.find(id)
  #   new App.ControllerGenericDestroyConfirm(
  #     item:      item
  #     container: @el.closest('.content')
  #     callback:  @load
  #   )

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.Twitter.description
      container:   @el.closest('.content')
    )

App.Config.set( 'Twitter', { prio: 5000, name: 'Twitter', parent: '#channels', target: '#channels/twitter', controller: Index, role: ['Admin'] }, 'NavBarAdmin' )