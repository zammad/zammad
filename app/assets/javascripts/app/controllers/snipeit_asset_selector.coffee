# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.SnipeitAssetSelector extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Snipe-IT')
  lastSearchTermEmpty: false

  content: ->
    content = App.view('integration/snipeit_asset_selector')()
    controller = @
    App.Delay.set( ->
      searchField = controller.el.find('input.js-searchField')
      
      # Auto-search with customer email if available (but don't show it in field)
      if controller.customerEmail
        console.log('Snipe-IT: Searching for customer email:', controller.customerEmail)
        controller.search({ search: controller.customerEmail })
      
      searchField.on('keyup', (e) ->
        params = controller.formParam(e.target)
        controller.search(params)
      )
      
      searchField.trigger('focus')
    , 100, 'snipeit-asset-selector-focus')
    content

  search: (filter) =>
    if _.isEmpty(filter.search)
      @lastSearchTermEmpty = true
      @renderResult([])
      return

    @lastSearchTermEmpty = false
    @ajax(
      id:    'snipeit-asset-selector'
      type:  'POST'
      url:   "#{@apiPath}/integration/snipeit/query"
      data:  JSON.stringify(method: 'hardware', search: filter.search)
      success: (data, status, xhr) =>
        return if @lastSearchTermEmpty
        if data.result && data.result.rows
          @renderResult(data.result.rows)
        else
          @renderResult([])

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @contentInline = __('Content could not be loaded.')
        @render()
    )

  renderResult: (items) =>
    table = App.view('integration/snipeit_asset_result')(
      items: items
    )
    @el.find('.js-result').html(table)

  onSubmit: (e) =>
    form = @el.find('.js-result')
    params = @formParam(form)
    return if _.isEmpty(params.asset_id)
    assetIds = []
    if _.isArray(params.asset_id)
      assetIds = params.asset_id
    else
      assetIds.push params.asset_id
    @callback(assetIds, @)
