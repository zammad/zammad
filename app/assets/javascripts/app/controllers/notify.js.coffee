$ = jQuery.sub()

class App.Notify extends Spine.Controller
  events:
    'click .alert': 'destroy'

  className: 'container'

  constructor: ->
    super
    
    Spine.bind 'notify', (data) =>
      @[data.type] data.msg

    Spine.bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

  info: (data) ->
    @render( text: arguments[0], type: 'information' )
    
  warning: (data) ->
    @render( text: arguments[0], type: 'alert' )
    
  error: (data) ->
    @render( text: arguments[0], type: 'error' )
    
  success: (data) ->
    @render( text: arguments[0], type: 'success' )
    
  render: (data) ->
#    notify = App.view('notify')(data: data)
#    @append( notify )
    $.noty.closeAll()
    $('#notify').noty(
      {
        text:             data.text,
        layout:           'top',
        type:             data.type,
        theme:            'noty_theme_twitter',
        animateOpen:      { height: 'toggle' },
        animateClose:     { height: 'toggle' },
        speed:            450,
        timeout:          3600,
        closeButton:      false,
        closeOnSelfClick: true,
        closeOnSelfOver:  false,
      }
    )
  
  destroy: (e) ->
    e.preventDefault()
#    $(e.target).parents('.alert').remove();

  destroyAll: ->
    $.noty.closeAll()
#    $(@el).find('.alert').remove();

