class Index extends App.ControllerContent
  className: 'getstarted fit'
  elements:
    '.input-feedback':                       'urlStatus'
    '[data-target=zendesk-credentials]':     'nextEnterCredentials'
    '[data-target=zendesk-start-migration]': 'nextStartMigration'
    '#zendesk-url':                          'zendeskUrl'
    '.js-zendeskUrlApiToken':                'zendeskUrlApiToken'
    '.zendesk-url-error':                    'linkErrorMessage'
    '.zendesk-api-token-error':              'apiTokenErrorMessage'
    '#zendesk-email':                        'zendeskEmail'
    '#zendesk-api-token':                    'zendeskApiToken'
    '.js-ticket-count-info':                 'ticketCountInfo'
  updateMigrationDisplayLoop: 0

  events:
    'click .js-zendesk-credentials': 'showCredentials'
    'click .js-migration-start':     'startMigration'
    'keyup #zendesk-url':           'updateUrl'
    'keyup #zendesk-api-token':     'updateApiToken'

  constructor: ->
    super

    # set title
    @title 'Import'

    # redirect to login if master user already exists
    if @Config.get('system_init_done')
      @navigate '#login'
      return

    @fetch()

  fetch: ->

    # get data
    @ajax(
      id:          'getting_started'
      type:        'GET'
      url:         "#{@apiPath}/getting_started"
      processData: true
      success:     (data, status, xhr) =>

        # check if import is active
        if data.import_mode == true && data.import_backend != 'zendesk'
          @navigate "#import/#{data.import_backend}"
          return

        # render page
        @render()

        if data.import_mode == true
          @showImportState()
          @updateMigration()
    )

  render: ->
    @html App.view('import/zendesk')()

  updateUrl: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @linkErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_zendesk_url'
        type:        'POST'
        url:         "#{@apiPath}/import/zendesk/url_check"
        data:        JSON.stringify(url: @zendeskUrl.val())
        processData: true
        success:     (data, status, xhr) =>

          # validate form
          console.log(data)
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @linkErrorMessage.text('')
            @nextEnterCredentials.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @linkErrorMessage.text( data.message_human || data.message)
            @nextEnterCredentials.addClass('hide')

      )
    @delay( callback, 700, 'import_zendesk_url' )

  updateApiToken: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @apiTokenErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_zendesk_api_token'
        type:        'POST'
        url:         "#{@apiPath}/import/zendesk/credentials_check"
        data:        JSON.stringify(username: @zendeskEmail.val(), token: @zendeskApiToken.val())
        processData: true
        success:     (data, status, xhr) =>

          # validate form
          console.log(data)
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @apiTokenErrorMessage.text('')
            @nextStartMigration.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @apiTokenErrorMessage.text(data.message_human || data.message)
            @nextStartMigration.addClass('hide')

      )
    @delay(callback, 700, 'import_zendesk_api_token')

  showCredentials: (e) =>
    e.preventDefault()
    @urlStatus.attr('data-state', '')
    url = @zendeskUrl.val() + '/agent/admin/api'
    @zendeskUrlApiToken.attr('href', url.replace(/([^:])\/\/+/g, '$1/'))
    @zendeskUrlApiToken.val('HERE')
    @$('[data-slide=zendesk-url]').toggleClass('hide')
    @$('[data-slide=zendesk-credentials]').toggleClass('hide')

  showImportState: =>
    @$('[data-slide=zendesk-url]').addClass('hide')
    @$('[data-slide=zendesk-credentials]').addClass('hide')
    @$('[data-slide=zendesk-import]').removeClass('hide')

  startMigration: (e) =>
    e.preventDefault()
    @showImportState()
    @ajax(
      id:          'import_start'
      type:        'POST'
      url:         "#{@apiPath}/import/zendesk/import_start"
      processData: true
      success:     (data, status, xhr) =>

        # validate form
        console.log(data)
        if data.result is 'ok'
          @delay(@updateMigration, 3000)
    )

  updateMigration: =>
    @updateMigrationDisplayLoop += 1
    @showImportState()
    @ajax(
      id:          'import_status'
      type:        'GET'
      url:         "#{@apiPath}/import/zendesk/import_status"
      processData: true
      success:     (data, status, xhr) =>

        if data.result is 'import_done'
          window.location.reload()
          return

        if data.result is 'error'
          @$('.js-error').removeClass('hide')
          @$('.js-error').html(App.i18n.translateContent(data.message))
        else
          @$('.js-error').addClass('hide')

        if data.message is 'not running' && @updateMigrationDisplayLoop > 16
          @$('.js-error').removeClass('hide')
          @$('.js-error').html(App.i18n.translateContent('Background process did not start or has not finished! Please contact your support.'))
          return

        if data.result is 'in_progress'
          for key, item of data.data
            if item.done > item.total
              item.done = item.total

            if key == 'Ticket' && item.total >= 1000
              @ticketCountInfo.removeClass('hide')

            element = @$('.js-' + key.toLowerCase() )
            element.find('.js-done').text(item.done)
            element.find('.js-total').text(item.total)
            element.find('progress').attr('max', item.total )
            element.find('progress').attr('value', item.done )
            if item.total <= item.done
              element.addClass('is-done')
            else
              element.removeClass('is-done')
        @delay(@updateMigration, 5000)
    )

App.Config.set('import/zendesk', Index, 'Routes')
App.Config.set('zendesk', {
  title: 'Zendesk'
  name:  'Zendesk'
  class: 'js-zendesk'
  url:   '#import/zendesk'
}, 'ImportPlugins')
