$ = jQuery.sub()

class App.Notify extends Spine.Controller
  events:
    'click .alert': 'destroy'

  className: 'container'

  constructor: ->
    super
    
    App.Event.bind 'notify', (data) =>
      @render(data)

    App.Event.bind 'notify:removeall', =>
      @log 'notify:removeall', @
      @destroyAll()

  render: (data) ->
#    notify = App.view('notify')(data: data)
#    @append( notify )

    # map noty naming
    if data['type'] is 'info'
      data['type'] = 'information'
    if data['type'] is 'warning'
      data['type'] = 'alert'

    $.noty.closeAll()
    if data.link
      data.msg = '<a href="' + data.link + '">' + data.msg + '</a>'
    $('#notify').noty(
      {
        text:     data.msg,
        layout:   'top',
        type:     data.type,
        theme:    'noty_theme_twitter',
        animateOpen: { 
          height: 'toggle'
          opacity: 0.85,
        },
        animateClose: {
          opacity: 0.25,
        },
        speed:            450,
        timeout:          data.timeout || 3800,
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

