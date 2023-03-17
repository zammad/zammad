class App.ControllerDrox extends App.Controller
  constructor: (params) ->
    super

    if params.data && ( params.data.text || params.data.html )
      @inline(params.data)

  inline: (data) ->
    @html App.view('generic/drox')(data)
    if data.text
      @$('.drox-body').text(data.text)
    if data.html
      @$('.drox-body').html(data.html)

  template: (data) ->
    drox = $( App.view('generic/drox')(data) )
    content = App.view(data.file)(data.params)
    drox.find('.drox-body').append(content)
    drox
