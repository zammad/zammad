class Index extends App.ControllerContent
  className: 'getstarted fit'
  elements:
    '.input-feedback':                      'urlStatus'
    '[data-target=otrs-start-migration]':   'nextStartMigration'
    '.otrs-link-error':                     'linkErrorMessage'
  events:
    'click .js-otrs-link':       'showLink'
    'click .js-download':        'startDownload'
    'click .js-migration-start': 'startMigration'
    'keyup #otrs-link':          'updateUrl'

  constructor: ->
    super

    # set title
    @title 'Import'

    @fetch()

    @bind('import:finished', =>
      console.log('import:finished')
      @Config.set('system_init_done', true)
      @navigate '#'
    )

  fetch: ->

    # get data
    @ajax(
      id:          'getting_started',
      type:        'GET',
      url:         @apiPath + '/getting_started',
      processData: true,
      success:     (data, status, xhr) =>

        # redirect to login if master user already exists
        if @Config.get('system_init_done')
          @navigate '#login'
          return

        # check if import is active
        if data.import_mode == true && data.import_backend != 'otrs'
          @navigate '#import/' + data.import_backend
          return

        # render page
        @render()

        if data.import_mode == true
          @showImportState()
          @updateMigration()
    )

  render: ->
    @html App.view('import/otrs')()

  startDownload: (e) =>
    e.preventDefault()
    @$('.js-otrs-link').removeClass('hide')

  showLink: (e) =>
    e.preventDefault()
    @$('[data-slide=otrs-plugin]').toggleClass('hide')
    @$('[data-slide=otrs-link]').toggleClass('hide')

  showImportState: =>
    @$('[data-slide=otrs-plugin]').addClass('hide')
    @$('[data-slide=otrs-link]').addClass('hide')
    @$('[data-slide=otrs-import]').removeClass('hide')

  updateUrl: (e) =>
    url = $(e.target).val()
    @urlStatus.attr('data-state', 'loading')
    @linkErrorMessage.text('')

    # get data
    callback = =>
      @ajax(
        id:          'import_otrs_url',
        type:        'POST',
        url:         @apiPath + '/import/otrs/url_check',
        data:        JSON.stringify(url: url)
        processData: true,
        success:     (data, status, xhr) =>

          # validate form
          if data.result is 'ok'
            @urlStatus.attr('data-state', 'success')
            @linkErrorMessage.text('')
            @nextStartMigration.removeClass('hide')
          else
            @urlStatus.attr('data-state', 'error')
            @linkErrorMessage.text( data.message_human || data.message )
            @nextStartMigration.addClass('hide')

      )
    @delay( callback, 700, 'import_otrs_url' )

  startMigration: (e) =>
    e.preventDefault()
    @showImportState()
    @ajax(
      id:          'import_start',
      type:        'POST',
      url:         @apiPath + '/import/otrs/import_start',
      processData: true,
      success:     (data, status, xhr) =>

        # validate form
        if data.result is 'ok'
          @delay( @updateMigration, 3000 )
    )


  updateMigration: =>
    @showImportState()
    @ajax(
      id:          'import_status',
      type:        'GET',
      url:         @apiPath + '/import/otrs/import_status',
      processData: true,
      success:     (data, status, xhr) =>

        if data.setup_done
          @Config.set('system_init_done', true)
          @navigate '#'
          return

        for key, item of data.data
          element = @$('.js-' + key.toLowerCase() )
          element.find('.js-done').text(item.done)
          element.find('.js-total').text(item.total)
          element.find('progress').attr('max', item.total )
          element.find('progress').attr('value', item.done )
          if item.total <= item.done
            element.addClass('is-done')
          else
            element.removeClass('is-done')
        @delay( @updateMigration, 5000 )
    )

App.Config.set( 'import/otrs', Index, 'Routes' )
App.Config.set( 'otrs', {
  image: 'otrs-logo.png'
  title: 'OTRS'
  name:  'OTRS'
  class: 'js-otrs'
  url:   '#import/otrs'
}, 'ImportPlugins' )
