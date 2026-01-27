# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SidebarSnipeit extends App.Controller
  sidebarItem: =>
    return if !@Config.get('snipeit_integration')

    isAgentTicketZoom   = (@ticket and @ticket.currentView() is 'agent')
    isAgentTicketCreate = (!@ticket and @taskKey and @taskKey.match('TicketCreateScreen-'))

    return if !isAgentTicketZoom and !isAgentTicketCreate

    @item = {
      name: 'snipeit'
      badgeIcon: 'printer'
      badgeCallback: @badgeRender
      sidebarHead: __('Snipe-IT')
      sidebarCallback: @showAssets
      sidebarActions: [
        {
          title:    __('Add Assets')
          name:     'assets-change'
          callback: @changeAssets
        },
      ]
    }
    @item

  changeAssets: =>
    customerEmail = null
    if @ticket && @ticket.customer_id && App.User.exists(@ticket.customer_id)
      customer = App.User.find(@ticket.customer_id)
      customerEmail = customer.email if customer.email
    
    new App.SnipeitAssetSelector(
      taskKey: @taskKey
      container: @el.closest('.content')
      customerEmail: customerEmail
      callback: (assetIds, assetSelectorUi) =>
        if @ticket && @ticket.id

          # add new assetIds to list of all @assetIds
          # and transfer the complete list to the backend
          @assetIds = @assetIds.concat(assetIds)

          @updateTicket(@ticket.id, @assetIds, =>
            assetSelectorUi.close()
            @showAssetsContent(assetIds)
          )
          return
        assetSelectorUi.close()
        @showAssetsContent(assetIds)
    )

  showAssets: (el) =>
    @el = el

    # show placeholder
    @assetIds ||= []
    if @ticket && @ticket.preferences && @ticket.preferences.snipeit && @ticket.preferences.snipeit.asset_ids
      @assetIds = @ticket.preferences.snipeit.asset_ids
    queryParams = @queryParam()
    if queryParams && queryParams.snipeit_asset_ids
      @assetIds.push queryParams.snipeit_asset_ids
    @showAssetsContent()

  badgeRender: (el) =>
    @badgeEl = el
    @badgeRenderLocal()

  badgeRenderLocal: =>
    assetCount = 0
    if @ticket && @ticket.preferences && @ticket.preferences.snipeit && @ticket.preferences.snipeit.asset_ids
      assetCount = @ticket.preferences.snipeit.asset_ids.length
    
    counter = if assetCount > 0 then assetCount else ''
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(
      name: 'snipeit'
      icon: 'printer'
      counterPossible: true
      counter: counter
    ))

  showAssetsContent: (assetIds) =>
    if assetIds
      @assetIds = @assetIds.concat(assetIds)
      @assetIds = _.uniq(@assetIds)

    # show placeholder
    if _.isEmpty(@assetIds)
      @html("<div>#{App.i18n.translateInline('none')}</div>")
      return

    # ajax call to show items
    @ajax(
      id:    "snipeit-#{@taskKey}"
      type:  'POST'
      url:   "#{@apiPath}/integration/snipeit/query"
      data:  JSON.stringify(method: 'hardware', ids: @assetIds)
      success: (data, status, xhr) =>
        if data.result
          @showList(data.result.rows)
          return
        @showError(__('Loading failed.'))

      error: (xhr, status, error) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @showError(__('Loading failed.'))
    )

  showList: (assets) =>
    list = $(App.view('ticket_zoom/sidebar_snipeit')(
      assets: assets
    ))
    list.on('click', '.js-delete', (e) =>
      e.preventDefault()
      assetId = $(e.currentTarget).attr 'data-asset-id'
      @delete(assetId)
    )
    @html(list)

  showError: (message) =>
    @html App.i18n.translateInline(message)

  reload: =>
    @showAssetsContent()

  delete: (assetId) =>
    localAssets = []
    for localAssetId in @assetIds
      if assetId.toString() isnt localAssetId.toString()
        localAssets.push localAssetId
    @assetIds = localAssets
    if @ticket && @ticket.id
      @updateTicket(@ticket.id, @assetIds)
    @showAssetsContent()

  postParams: (args) =>
    return if !args.ticket
    return if args.ticket.created_at
    return if !@assetIds
    return if _.isEmpty(@assetIds)
    args.ticket.preferences ||= {}
    args.ticket.preferences.snipeit ||= {}
    args.ticket.preferences.snipeit.asset_ids = @assetIds

  updateTicket: (ticket_id, assetIds, callback) =>
    App.Ajax.request(
      id:    "snipeit-update-#{ticket_id}"
      type:  'POST'
      url:   "#{@apiPath}/integration/snipeit/update"
      data:  JSON.stringify(ticket_id: ticket_id, asset_ids: assetIds)
      success: (data, status, xhr) =>
        # Update local ticket object to reflect new asset count
        if @ticket
          @ticket.preferences ||= {}
          @ticket.preferences.snipeit ||= {}
          @ticket.preferences.snipeit.asset_ids = assetIds
        @badgeRenderLocal()
        if callback
          callback(assetIds)

      error: (xhr, status, details) =>

        # do not close window if request is aborted
        return if status is 'abort'

        # show error message
        @log 'errors', details
        @notify(
          type:    'error'
          msg:     details.error_human || details.error || __('The asset could not be updated.')
          timeout: 6000
        )
    )

App.Config.set('500-Snipeit', SidebarSnipeit, 'TicketCreateSidebar')
App.Config.set('500-Snipeit', SidebarSnipeit, 'TicketZoomSidebar')
