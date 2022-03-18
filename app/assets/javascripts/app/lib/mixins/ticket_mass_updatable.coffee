InstanceMethods =
  ajax_mass_update: (data, success) ->
    @ajax_mass('update', data, success)

  ajax_mass_macro: (data, success) ->
    @ajax_mass('macro', data, success)

  ajax_mass: (path, data, success) ->
    @startLoading()

    @ajax(
      id: 'bulk_update'
      type: 'POST'
      url:   "#{@apiPath}/tickets/mass_#{path}"
      data: JSON.stringify(data)
      success: (data) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        App.Event.trigger('overview:fetch')
        App.Event.trigger('notify', {
          type: 'success'
          msg: App.i18n.translateContent(__('Bulk action executed!'))
        })

        success?()

      error: (xhr, status, error) =>
        @stopLoading()

        return if xhr.status != 422

        message = if xhr.responseJSON.error && ticket = App.Ticket.find(xhr.responseJSON.ticket_id)
                    App.i18n.translateContent(__('Ticket failed to save: %s'), ticket.title)
                  else
                    error

        new App.ErrorModal(
          head: __('Bulk action failed')
          contentInline: message
          container: @el.closest('.content')
        )
    )

App.TicketMassUpdatable =
  extended: ->
    @include InstanceMethods
