$ = jQuery.sub()

class App.TextModuleUI extends App.Controller
  events:
    'click [data-type=text_module_save]':   'create',
    'click [data-type=text_module_select]': 'select',
    'click [data-type=text_module_delete]': 'delete',
    'click [data-type=edit]':               'select',
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
    a = $('textarea')

    # remember active text element
    a.bind('focusin', ->
      ui.area = $(@)
    )

    ui.C = false
    ui.CList = ''
    a.bind('keydown', (e) ->

      # lisen if crtl is pressed
      if ui.C
        key = App.ClipBoard.keycode( e.keyCode )

        # remove one char
        if key is 'backspace'
          ui.CList = ui.CList.slice( 0, -1 )

        # take over
        else if key is 'enter'
#          ui.CList = ui.CList.slice(0, -1)
          objects = ui.objectSearch( ui.CList )
          if objects[0]
            ui._insert( objects[0].content, ui )

            # reset search
            ui.CList = ''
            ui.renderTable()

        # add char to search selection
        else
          ui.CList = ui.CList + key

        console.log 'CTRL+', ui.CList
        ui.el.find('#text-module-search').val( ui.CList )
        ui.renderTable( ui.CList )

      # start current search process
      if e.ctrlKey
        ui.C = true
    )

    # start current search process
    # do code to test other keys
    a.bind('keyup', (e) ->
      if e.keyCode == 17
        console.log 'CTRL UP - pressed ', ui.CList
        ui.CList = ''
        ui.C = false
        ui.renderTable()
    )

    @configure_attributes = [
      { name: 'text_module_id', display: '', tag: 'select', multiple: false, null: true, nulloption: true, relation: 'TextModule', class: 'span2', default: @text_module_id  },
    ]

    text_module = {}
    if @text_module_id
      text_module = App.Collection.find( 'TextModule', @text_module_id )

    # insert data
    @html App.view('text_module')(
      text_module: text_module,
      search: @search,
    )

    # rerender if search phrase has changed
    @el.find('#text-module-search').unbind('keyup').bind('keyup', =>
      search = $('#text-module-search').val();
      console.log 'SEARCH', search
      @renderTable( search )
    )

    @renderTable('')

  objectSearch: (search) =>
    objects = App.Collection.all(
      type: 'TextModule',
      sortBy: 'name',
      filter: { active: true },
      filterExtended: [ { name: search }, { content: search }, { keywords: search } ],
    )


  renderTable: (search) =>

    objects = @objectSearch(search)

    @el.find('#form-text-module').html('')
    new App.ControllerTable(
      el: @el.find('#form-text-module'),
#      header:   ['Name'],
      overview: ['name'],
      model:    App.TextModule,
      objects:  objects,
#      radio:    true,
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
      @text_module_id = undefined
      @render()

  select: (e) =>
    e.preventDefault()
    id = $(e.target).parents('tr').data('id')
    text_module = App.Collection.find( 'TextModule', id )
    @el.find('#text-module-preview-content').val( text_module.content )

  create: (e) =>
    e.preventDefault()

    # get params
    params = @formParam(e.target)
    name = params['text_module_name']
#    delete params['text_module_name']

    text_module = App.Collection.findByAttribute( 'TextModule', 'name', name )
    if !text_module
      text_module = new App.TextModule

    content = App.ClipBoard.getSelectedLast()
    if content
      text_module.load(
        name:    params['text_module_name']
        content: content
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
          ui.text_module_id = @.id
          ui.render()
          ui.log 'save success!'

        error: ->
          ui.log 'save failed!'
      )

  _insert: (contentNew, ui) ->
    position = ui.area.prop('selectionStart')
    content = ui.area.val()
    start = content.substr( 0, position )
    end   = content.substr( position, content.length )

    # check if \n is needed
    startEnd = start.substr( start.length-2, 2 )

    if position is 0 || startEnd is "\n\n"
      startDiver = ''
    else
      startDiver = "\n"
    content = start + startDiver + contentNew + end
    ui.area.val(content)

    # update cursor position
    currentPosition = (position + contentNew.length + startDiver.length )
    ui.area.prop('selectionStart', currentPosition )
    ui.area.prop('selectionEnd', currentPosition )

