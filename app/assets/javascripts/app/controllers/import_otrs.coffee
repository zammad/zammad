class ImportOtrs extends App.ControllerWizardFullScreen
  className: 'getstarted fit'
  elements:
    '.input-feedback':     'urlStatus'
    '.js-migration-check': 'nextStartMigration'
    '.otrs-link-error':    'linkErrorMessage'

  events:
    'click .js-otrs-link':       'showLink'
    'click .js-download':        'startDownload'
    'click .js-migration-start': 'startMigration'
    'click .js-migration-check': 'checkMigration'
    'keyup #otrs-link':          'updateUrl'
  updateMigrationDisplayLoop: 0

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
        if data.import_mode == true && data.import_backend != 'otrs'
          @navigate "#import/#{data.import_backend}", { emptyEl: true }
          return

        # render page
        @render()

        if data.import_mode == true
          @showImportState()
          @updateMigration()
    )

  render: ->
    @replaceWith App.view('import/otrs')()

  startDownload: (e) =>
    @$('.js-otrs-link').removeClass('hide')

  showLink: (e) =>
    e.preventDefault()
    @$('[data-slide=otrs-plugin]').toggleClass('hide')
    @$('[data-slide=otrs-link]').toggleClass('hide')

  showImportState: =>
    @$('[data-slide=otrs-plugin]').addClass('hide')
    @$('[data-slide=otrs-link]').addClass('hide')
    @$('[data-slide=otrs-import]').removeClass('hide')
    @$('[data-slide=otrs-import-notice]').addClass('hide')

  showImportNotice: =>
    @$('[data-slide=otrs-plugin]').addClass('hide')
    @$('[data-slide=otrs-link]').addClass('hide')
    @$('[data-slide=otrs-import]').addClass('hide')
    @$('[data-slide=otrs-import-notice]').removeClass('hide')

  updateUrl: (e) =>
    url = $(e.target).val()
    @urlStatus.attr('data-state', 'loading')
    @linkErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_otrs_url'
        type:        'POST'
        url:         "#{@apiPath}/import/otrs/url_check"
        data:        JSON.stringify(url: url)
        processData: true
        success:     (data, status, xhr) =>

          # validate form
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @linkErrorMessage.text('')
            @nextStartMigration.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @linkErrorMessage.text(data.message_human || data.message)
            @nextStartMigration.addClass('hide')
      )
    @delay(callback, 700, 'import_otrs_url')

  checkMigration: (e) =>
    e.preventDefault()
    @ajax(
      id:          'import_otrs_check'
      type:        'POST'
      url:         "#{@apiPath}/import/otrs/import_check"
      processData: true
      success:     (data, status, xhr) =>
        if data.result is 'ok'
          @startMigration()
          return
        for issue in data.issues
          @$(".js-#{issue}").removeClass('hide')
        @showImportNotice()
    )

  startMigration: (e) =>
    if e
      e.preventDefault()
    @showImportState()
    @ajax(
      id:          'import_start'
      type:        'POST'
      url:         "#{@apiPath}/import/otrs/import_start"
      processData: true
      success:     (data, status, xhr) =>
        if data.result is 'ok'
          @delay(@updateMigration, 2000)
    )

  updateMigration: =>
    @updateMigrationDisplayLoop += 1
    @showImportState()
    @ajax(
      id:          'import_status'
      type:        'GET'
      url:         "#{@apiPath}/import/otrs/import_status"
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

        if data.message is 'not running' && @updateMigrationDisplayLoop > 10
          @$('.js-error').removeClass('hide')
          @$('.js-error').html(App.i18n.translateContent('Background process did not start or has not finished! Please contact your support.'))
          return

        if data.result is 'in_progress'
          for key, item of data.data
            if item.done > item.total
              item.done = item.total
            element = @$('.js-' + key.toLowerCase())
            element.find('.js-done').text(item.done)
            element.find('.js-total').text(item.total)
            element.find('progress').attr('max', item.total)
            element.find('progress').attr('value', item.done)
            if item.total <= item.done
              element.addClass('is-done')
            else
              element.removeClass('is-done')
        @delay(@updateMigration, 6500)
    )

App.Config.set('import/otrs', ImportOtrs, 'Routes')
App.Config.set('otrs', {
  title: 'OTRS'
  name:  'OTRS'
  class: 'js-otrs'
  url:   '#import/otrs'
}, 'ImportPlugins')
