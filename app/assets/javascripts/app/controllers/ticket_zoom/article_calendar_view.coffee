class App.TicketZoomArticleCalendarView extends App.ControllerModal
  shown: false
  buttonClose: true
  buttonCancel: true
  buttonSubmit: 'Download'
  buttonClass: 'btn--success'
  head: ''
  calendarPreview: ''

  events:
    'submit form':      'submit'
    'click .js-cancel': 'cancel'
    'click .js-close':  'cancel'

  constructor: ->
    super
    @fetch()

  fetch: =>
    attachment_preview_url = $(@calendar).data('preview-url')
    attachment_id = $(@calendar).data('id')
    @ajax(
      id:    "calendar_preview_#{attachment_id}"
      type:  'GET'
      url:   "#{attachment_preview_url}&type=calendar"
      processData: true
      success: (data, status, xhr) =>
        @calendarPreview = App.view('generic/calender_preview')(
          events: data.events
        )
        @render()

      error: (xhr) ->
        statusText = xhr.statusText
        rawResponseText     = xhr.responseText

        # ignore if request is aborted
        return if statusText is 'abort'

        try
          json = JSON.parse(rawResponseText)
          text = json.error_human || json.error

        text = rawResponseText if !text
        errorMessage = App.i18n.translateContent(text || 'Could not process your request')

        # show error message
        new App.ControllerTechnicalErrorModal(
          contentCode: errorMessage
          head:        App.i18n.translateContent('An error has occurred')
        )
      )

  content: =>
    "<div class=\"justified vertical calendar-preview\">#{@calendarPreview}</div>"

  onSubmit: =>
    url = "#{$(@calendar).attr('href')}"
    window.open(url, '_blank')
