class App.TextModuleUI extends App.Controller
  constructor: ->
    super
    ui = @
    values = []
    all = App.Collection.all( type: 'TextModule' )
    for item in all
      if item.active is true
        contentNew = item.content.replace( /<%=\s{0,2}(.+?)\s{0,2}%>/g, ( all, key ) ->
          key = key.replace( /@/g, 'ui.data.' )
          varString = "#{key}" + ''
          try
            key = eval (varString)
          catch error
    #        console.log( "tag replacement: " + error )
            key = ''
          return key
        )
        value = { val: contentNew, keywords: item.keywords || item.name }
        values.push value

    customItemTemplate = "<div><span />&nbsp;<small /></div>"
    elementFactory = (element, e) ->
      template = $(customItemTemplate).find('span')
                          .text(e.val).end()
                          .find('small')
                          .text("(" + e.keywords + ")").end()
      element.append(template)
    @el.find('textarea').sew({values: values, token: '::', elementFactory: elementFactory })

class App.TextModuleUIOld extends App.Controller
  events:
    'click [data-type=save]':               'create',
    'click [data-type=text_module_delete]': 'delete',
    'click [data-type=edit]':               'select',
    'click .close':                         'close',
    'dblclick [data-type=edit]':            'paste',

  constructor: ->
    super

    # fetch item on demand
    fetch_needed = 1
    if App.Collection.count( 'TextModule' ) > 0
      fetch_needed = 0
      @render()

    if fetch_needed
      @reload()

  reload: =>
      App.TextModule.bind 'refresh', =>
        @log 'loading....'
        @render()
        App.TextModule.unbind 'refresh'
      App.Collection.fetch( 'TextModule' )

  render: =>

    ui = @
    ui.Capture = false
    ui.CaptureList = ''

    # define elements to observe
    inputElement = $('textarea')

    # set first text element to active
    ui.area = $( inputElement[0] )

    # remember active text element
    inputElement.bind('focusin', ->
      @uiWidget = ui
      @uiWidget.el.find('.well').removeClass('hide')
      ui.area = $(@)

      # set window to new possition
      update = =>
        left  = @uiWidget.area.offset().left
        top   = @uiWidget.area.offset().top
        width = @uiWidget.area.width()

        topWindow = $(window).scrollTop() + 50
        if top < topWindow
          @uiWidget.el.offset( top: topWindow )
        else
          @uiWidget.el.offset( left: left + width + 20, top: top )

      # update window possition every x ms
      ui.interval( update, 100, 'text_module_box' )
    )
    inputElement.bind('focusout', ->

      # clear update window possition
      ui.clearInterval( 'text_module_box' )
    )

    inputElement.bind('keydown', (e) ->

      # lisen if crtl is pressed
      if ui.Capture

        # lookup key
        key = App.ClipBoard.keycode( e.keyCode )

        # remove one char
        if key is 'backspace'

          # prevent default key action
          e.preventDefault()

          ui.CaptureList = ui.CaptureList.slice( 0, -1 )

        # take over
        else if key is 'enter'

          # prevent default key action
          e.preventDefault()

          objects = ui.objectSearch( ui.CaptureList )
          if objects[0]
            ui._insert( objects[0].content, ui )

            # reset search
            ui.CaptureList = ''
            ui.renderTable()

        # add space to search selection
        else if key is 'space'

          # prevent default key action
          e.preventDefault()

          ui.CaptureList = ui.CaptureList + ' '

        # add char to search selection
        else if key.length is 1
          ui.CaptureList = ui.CaptureList + key

          # prevent default key action
          e.preventDefault()

#        console.log 'CTRL+', ui.CaptureList
        ui.el.find('#text-module-search').val( ui.CaptureList )
        ui.renderTable( ui.CaptureList )

      # start current search process
      if e.ctrlKey
        ui.Capture = true
    )

    # start current search process
    # do code to test other keys
    inputElement.bind('keyup', (e) ->
      if e.keyCode == 17
        ui.CaptureList = ''
#        console.log 'CTRL UP - pressed ', ui.CaptureList
        ui.Capture = false
        ui.el.find('#text-module-search').val( '' )
        ui.renderTable()
    )

    # insert data
    @html App.view('text_module_widget')(
      search: @search,
    )

    # rerender if search phrase has changed
    @el.find('#text-module-search').unbind('keyup').bind('keyup', =>
      search = $('#text-module-search').val()
      @renderTable( search )
    )

    @renderTable('')

  objectSearch: (search) =>
    objects = App.Collection.all(
      type:   'TextModule',
      sortBy: 'name',
      filter: { active: true },
      filterExtended: [ { name: "^#{search}" }, { content: search }, { keywords: search } ],
    )

  renderTable: (search) =>

    objects = @objectSearch(search)

    @el.find('#form-text-module').html('')
    new App.ControllerTable(
      el: @el.find('#form-text-module'),
      header:   [],
      overview: ['name'],
      model:    App.TextModule,
      objects:  objects,
#      radio:    true,
    )

    # remove old popovers
#    @el.find('.popover-inner').parent().remove()
    $('.popover').remove()

    # show user popup    
    @el.find('#form-text-module').find('.item').popover(
      trigger: 'hover'
      html:    true
      delay:   { show: 500, hide: 1200 }
#      placement: 'top'
      placement: 'right'
      title: ->
        id = $(@).data('id')
        text_module = App.Collection.find( 'TextModule', id )
        text_module.name
      content: ->
        id = $(@).data('id')
        text_module = App.Collection.find( 'TextModule', id )
        text_module.content
    )

  paste: (e) =>
    e.preventDefault()
    id = $(e.target).parents('tr').data('id')
    text_module = App.Collection.find( 'TextModule', id )
    @_insert( text_module.content, @ )

  delete: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    text_module = App.Collection.find( 'TextModule', params['text_module_id'] )
    if confirm('Sure?')
      text_module.destroy() 
      @render()

  select: (e) =>
    e.preventDefault()
    id = $(e.target).parents('tr').data('id')
    text_module = App.Collection.find( 'TextModule', id )
    @el.find('#text-module-preview-content').val( text_module.content )
    @el.find('#text_module_name').val( text_module.name )

  create: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    name = params['name']
#    delete params['text_module_name']

    text_module = App.Collection.findByAttribute( 'TextModule', 'name', name )
    if !text_module
      text_module = new App.TextModule

    content = App.ClipBoard.getSelectedLast()
    text_module.load(
      name:    params['name'],
      content: content,
      active:  true,
    )

    # validate form
    errors = text_module.validate()

    # show errors in form
    if errors
      @log 'error new', errors
    else
      ui = @
      text_module.save(
        success: ->
          ui.el.find('#text_module_name').val('')
          ui.renderTable()
          ui.log 'save success!'

        error: ->
          ui.log 'save failed!'
      )

  close: (e) =>
    e.preventDefault()
    @el.find('.well').addClass('hide')
    @clearInterval( 'text_module_box' )

  _insert: (contentNew, ui) ->
    position = ui.area.prop('selectionStart')
    content = ui.area.val()
    start = content.substr( 0, position )
    end   = content.substr( position, content.length )

    contentNew = contentNew.replace( /<%=\s{0,2}(.+?)\s{0,2}%>/g, ( all, key ) ->
      key = key.replace( /@/g, 'ui.data.' )
      varString = "#{key}" + ''
      try
        key = eval (varString)
      catch error
#        console.log( "tag replacement: " + error )
        key = ''
      return key
    )

    # check if \n is needed
    startEnd = start.substr( start.length-2, 2 )

    if position is 0 || startEnd is "\n\n"
      startDiver = ''
    else
      startDiver = "\n"
    content = start + startDiver + contentNew + end
    ui.area.val(content)

    # update cursor position
    currentPosition = ( position + contentNew.length + startDiver.length + 1 )
    ui.area.prop('selectionStart', currentPosition )
    ui.area.prop('selectionEnd', currentPosition )

