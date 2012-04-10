Spine ?= require('spine')
$      = Spine.$

class Spine.Tabs extends Spine.Controller
  events: 
    'click [data-name]': 'click'
    
  constructor: ->
    super
    @bind 'change', @change

  change: (name) => 
    return unless name
    @current = name
    @children().removeClass('active')
    @children("[data-name=#{@current}]").addClass('active')
  
  render: ->
    @change @current
    unless @children('.active').length or @current
      @children(':first').click()

  children: (sel) ->
    @el.children(sel)

  click: (e) ->
    name = $(e.currentTarget).attr('data-name')
    @trigger('change', name)

  connect: (tabName, controller) ->
    @bind 'change', (name) ->
      controller.active() if name is tabName
    controller.bind 'active', =>
      @change tabName
      
module?.exports = Spine.Tabs
