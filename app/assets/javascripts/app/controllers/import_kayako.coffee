class ImportKayako extends App.ControllerWizardFullScreen
  className: 'getstarted fit'
  elements:
    '.input-feedback':                         'urlStatus'
    '[data-target=kayako-credentials]':     'nextEnterCredentials'
    '[data-target=kayako-start-migration]': 'nextStartMigration'
    '#kayako-subdomain':                    'kayakoSubdomain'
    '#kayako-subdomain-addon':              'kayakoSubdomainAddon'
    '.kayako-subdomain-error':              'linkErrorMessage'
    '.kayako-password-error':              'apiTokenErrorMessage'
    '#kayako-email':                        'kayakoEmail'
    '#kayako-password':                    'kayakoPassword'
    '.js-ticket-count-info':                   'ticketCountInfo'
  updateMigrationDisplayLoop: 0

  events:
    'click .js-kayako-credentials': 'showCredentials'
    'click .js-migration-start':     'startMigration'
    'keyup #kayako-subdomain':           'updateUrl'
    'keyup #kayako-password':     'updateCredentials'

  constructor: ->
    super

    # set title
    @title 'Import'

    @kayakoDomain = '.kayako.com'

    # redirect to login if admin user already exists
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
        if data.import_mode == true && data.import_backend != 'kayako'
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # render page
        @render()

        if data.import_mode == true
          @showImportState()
          @updateMigration()
    )

  render: ->
    @replaceWith App.view('import/kayako')(
      kayakoDomain: @kayakoDomain
    )

  updateUrl: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @kayakoSubdomainAddon.attr('style', 'padding-right: 42px')
    @linkErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_kayako_url'
        type:        'POST'
        url:         "#{@apiPath}/import/kayako/url_check"
        data:        JSON.stringify(url: "https://#{@kayakoSubdomain.val()}#{@kayakoDomain}")
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
    @delay( callback, 700, 'import_kayako_url' )

  updateCredentials: (e) =>
    @urlStatus.attr('data-state', 'loading')
    @apiTokenErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_kayako_api_token'
        type:        'POST'
        url:         "#{@apiPath}/import/kayako/credentials_check"
        data:        JSON.stringify(username: @kayakoEmail.val(), password: @kayakoPassword.val())
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
    @delay(callback, 700, 'import_kayako_api_token')

  showCredentials: (e) =>
    e.preventDefault()
    @urlStatus.attr('data-state', '')
    @$('[data-slide=kayako-subdomain]').toggleClass('hide')
    @$('[data-slide=kayako-credentials]').toggleClass('hide')

  showImportState: =>
    @$('[data-slide=kayako-subdomain]').addClass('hide')
    @$('[data-slide=kayako-credentials]').addClass('hide')
    @$('[data-slide=kayako-import]').removeClass('hide')

  startMigration: (e) =>
    e.preventDefault()
    @showImportState()
    @ajax(
      id:          'import_start'
      type:        'POST'
      url:         "#{@apiPath}/import/kayako/import_start"
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
      url:         "#{@apiPath}/import/kayako/import_status"
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
          @redirectToLogin()
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

App.Config.set('import/kayako', ImportKayako, 'Routes')
App.Config.set('kayako', {
  title: 'Kayako'
  name:  'Kayako'
  class: 'js-kayako'
  url:   '#import/kayako'
}, 'ImportPlugins')
