class App.SSLCertificateController extends App.Controller
  events:
    'click .js-addCertificate': 'addCertificate'

  constructor: ->
    super
    @render()

  render: =>
    @html App.view('ssl_certificates')()
    @certList()

  certList: =>
    @list = new List(el: @$('.js-certificatesList'))

  addCertificate: =>
    new Certificate(
      callback: =>
        @list.load()
    )

class List extends App.Controller
  events:
    'click .js-remove': 'remove'

  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      type:  'GET'
      url:   "#{@apiPath}/ssl_certificates"
      success: (data, status, xhr) =>
        certificates = _.values(data.SSLCertificate)
        certificates = _.sortBy(certificates, (elem) -> elem.subject)

        @render(certificates)

      error: (data, status) =>
        return if status is 'abort'

        details = data.responseJSON || {}
        @notify(
          type: 'error'
          msg:  details.error_human || details.error || __('Loading failed.')
        )
    )

  render: (data) =>
    @html App.view('ssl_certificates_list')(
      certificates: data
    )

  remove: (e) =>
    e.preventDefault()
    id = $(e.currentTarget).parents('tr').data('id')
    return if !id

    new App.ControllerConfirm(
      message:     __('Are you sure?')
      container:   @el.closest('.content')
      buttonClass: 'btn--danger'
      callback: =>
        @ajax(
          type:  'DELETE'
          url:   "#{@apiPath}/ssl_certificates/#{id}"
          success: (data, status, xhr) =>
            @load()

          error: (data, status) =>
            return if status is 'abort'

            details = data.responseJSON || {}

            @notify(
              type: 'error'
              msg:  details.error_human || details.error || __('Server operation failed.')
            )
        )
    )

class Certificate extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Add')
  autoFocusOnFirstInput: false
  head: __('Add Certificate')
  large: true

  content: ->
    App.view('ssl_certificates_create')()

  onSubmit: (e) =>
    params = new FormData($(e.currentTarget).closest('form').get(0))

    @formDisable(e)
    @clearAlerts()

    @ajax(
      type:        'POST'
      url:         "#{@apiPath}/ssl_certificates"
      processData: false
      contentType: false
      cache:       false
      data:        params
      success:     (data, status, xhr) =>
        @close()
        @callback()
      error: (data) =>
        @formEnable(e)

        message = data?.responseJSON?.error_human || data?.responseJSON?.error || __('The import failed.')

        @showAlert(App.i18n.translateContent(message))
    )
