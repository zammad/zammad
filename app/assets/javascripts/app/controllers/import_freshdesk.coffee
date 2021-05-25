class ImportFreshdesk extends App.ControllerWizardFullScreen
  className: 'getstarted fit'
  elements:
    '.input-feedback':                         'urlStatus'
    '[data-target=freshdesk-credentials]':     'nextEnterCredentials'
    '[data-target=freshdesk-start-migration]': 'nextStartMigration'
    '#freshdesk-subdomain':                    'freshdeskSubdomain'
    '#freshdesk-subdomain-addon':              'freshdeskSubdomainAddon'
    '.freshdesk-subdomain-error':              'linkErrorMessage'
    '.freshdesk-api-token-error':              'apiTokenErrorMessage'
    '#freshdesk-email':                        'freshdeskEmail'
    '#freshdesk-api-token':                    'freshdeskApiToken'
    '.js-ticket-count-info':                   'ticketCountInfo'
  updateMigrationDisplayLoop: 0

  events:
    'click .js-freshdesk-credentials': 'showCredentials'
    'click .js-migration-start':     'startMigration'
    'keyup #freshdesk-subdomain':           'updateUrl'
    'keyup #freshdesk-api-token':     'updateApiToken'

  constructor: ->
    super

    # set title
    @title 'Import'

    @freshdeskDomain = '.freshdesk.com'

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
        if data.import_mode == true && data.import_backend != 'freshdesk'
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # render page
        @render()

        if data.import_mode == true
          @showImportState()
          @updateMigration()
    )

  render: ->
    @replaceWith App.view('import/freshdesk')(
      freshdeskDomain: @freshdeskDomain
    )

  updateUrl: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @freshdeskSubdomainAddon.attr('style', 'padding-right: 42px')
    @linkErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_freshdesk_url'
        type:        'POST'
        url:         "#{@apiPath}/import/freshdesk/url_check"
        data:        JSON.stringify(url: "https://#{@freshdeskSubdomain.val()}#{@freshdeskDomain}")
        processData: true
        success:     (data, status, xhr) =>

          # validate form
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @linkErrorMessage.text('')
            @nextEnterCredentials.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @linkErrorMessage.text( data.message_human || data.message)
            @nextEnterCredentials.addClass('hide')

      )
    @delay( callback, 700, 'import_freshdesk_url' )

  updateApiToken: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @apiTokenErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_freshdesk_api_token'
        type:        'POST'
        url:         "#{@apiPath}/import/freshdesk/credentials_check"
        data:        JSON.stringify(token: @freshdeskApiToken.val())
        processData: true
        success:     (data, status, xhr) =>

          # validate form
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @apiTokenErrorMessage.text('')
            @nextStartMigration.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @apiTokenErrorMessage.text(data.message_human || data.message)
            @nextStartMigration.addClass('hide')

      )
    @delay(callback, 700, 'import_freshdesk_api_token')

  showCredentials: (e) =>
    e.preventDefault()
    @urlStatus.attr('data-state', '')
    @$('[data-slide=freshdesk-subdomain]').toggleClass('hide')
    @$('[data-slide=freshdesk-credentials]').toggleClass('hide')

  showImportState: =>
    @$('[data-slide=freshdesk-subdomain]').addClass('hide')
    @$('[data-slide=freshdesk-credentials]').addClass('hide')
    @$('[data-slide=freshdesk-import]').removeClass('hide')

  startMigration: (e) =>
    e.preventDefault()
    @showImportState()
    @ajax(
      id:          'import_start'
      type:        'POST'
      url:         "#{@apiPath}/import/freshdesk/import_start"
      processData: true
      success:     (data, status, xhr) =>

        # validate form
        if data.result is 'ok'
          @delay(@updateMigration, 3000)
    )

  updateMigration: =>
    @updateMigrationDisplayLoop += 1
    @showImportState()
    @ajax(
      id:          'import_status'
      type:        'GET'
      url:         "#{@apiPath}/import/freshdesk/import_status"
      processData: true
      success:     (data, status, xhr) =>

        if _.isEmpty(data.result) && @updateMigrationDisplayLoop > 16
          @$('.js-error').removeClass('hide')
          @$('.js-error').html(App.i18n.translateContent('Background process did not start or has not finished! Please contact your support.'))
          return

        if !_.isEmpty(data.result['error'])
          @$('.js-error').removeClass('hide')
          @$('.js-error').html(App.i18n.translateContent(data.result['error']))
        else
          @$('.js-error').addClass('hide')

        if !_.isEmpty(data.finished_at) && _.isEmpty(data.result['error'])
          window.location.reload()
          return

        if !_.isEmpty(data.result)
          for model, stats of data.result
            if stats.sum > stats.total
              stats.sum = stats.total

            element = @$('.js-' + model.toLowerCase() )
            element.find('.js-done').text(stats.sum)
            element.find('.js-total').text(stats.total)
            element.find('progress').attr('max', stats.total )
            element.find('progress').attr('value', stats.sum )
            if stats.total <= stats.sum
              element.addClass('is-done')
            else
              element.removeClass('is-done')
        @delay(@updateMigration, 5000)
    )

App.Config.set('import/freshdesk', ImportFreshdesk, 'Routes')
App.Config.set('freshdesk', {
  title: 'Freshdesk'
  name:  'Freshdesk'
  class: 'js-freshdesk'
  url:   '#import/freshdesk'
}, 'ImportPlugins')
