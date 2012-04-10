$ = jQuery.sub()
#Post = App.Post

class App.Notify extends Spine.Controller
  events:
    'click .alert': 'destroy'

  className: 'container'

  constructor: ->
    super
    
    Spine.bind 'notify', (data) =>
#      @log 'bind notify', data
      @[data.type] data.msg

    Spine.bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

  info: (data) ->
    @render( text: arguments[0], type: 'alert-info' )
    
  warning: (data) ->
    @render( text: arguments[0], type: 'alert-warning' )
    
  error: (data) ->
    @render( text: arguments[0], type: 'alert-error' )
    
  success: (data) ->
    @render( text: arguments[0], type: 'alert-success' )
    
  render: (data) ->
    notify = App.view('notify')(data: data)
    @append( notify )
#    notify.html('')

  destroy: (e) ->
    e.preventDefault()
    $(e.target).parents('.alert').remove();

  destroyAll: ->
    $(@el).find('.alert').remove();

