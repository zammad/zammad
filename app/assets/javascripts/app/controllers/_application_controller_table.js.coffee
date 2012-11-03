class App.ControllerTable extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value

    @table = @tableGen(params)
    if @el
      @el.append( @table )

  ###

    new App.ControllerTable(
      header:   ['Host', 'User', 'Adapter', 'Active'],
      overview: ['host', 'user', 'adapter', 'active'],
      model:    App.Channel,
      objects:  data,
      checkbox: false,
      radio:    false,
    )

    new App.ControllerTable(
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
        { name: 'customer',               class: 'user-data', data: { id: true } },
        { name: 'ticket_state',           translate: true },
        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
        { name: 'owner',                  class: 'user-data', data: { id: true } },
        { name: 'created_at',             callback: @frontendTime },
        { name: 'last_contact',           callback: @frontendTime },
        { name: 'last_contact_agent',     callback: @frontendTime },
        { name: 'last_contact_customer',  callback: @frontendTime },
        { name: 'first_response',         callback: @frontendTime },
        { name: 'close_time',             callback: @frontendTime },
      ],
      model:    App.Ticket,
      objects:  tickets,
      checkbox: false,
      radio:    false,
    )

  ###

  tableGen: (data) ->
    overview   = data.overview || data.model.configure_overview || []
    attributes = data.attributes || data.model.configure_attributes || {}
    header     = data.header

    # check if table is empty
    if _.isEmpty(data.objects)
      table = '<span>-' + App.i18n.translateContent( 'none' ) + '-</span>'
      return $(table)

    # define normal header
    if header
      header_new = []
      for key in header
        header_new.push {
          display: key
        }
      header = header_new
    else if !data.overview_extended
      header = []
      for row in overview
        if attributes
          for attribute in attributes
            if row is attribute.name
              header.push attribute
            else
              rowWithoutId = row + '_id'
              if rowWithoutId is attribute.name
                header.push  attribute

    dataTypesForCols = []
    for row in overview
      dataTypesForCols.push {
        name: row
        link: true
      }

    # extended table format
    if data.overview_extended
      if !header
        header = []
        for row in data.overview_extended
          for attribute in attributes
            if row.name is attribute.name
              header.push attribute
            else
              rowWithoutId = row.name + '_id'
              if rowWithoutId is attribute.name
                header.push attribute

      dataTypesForCols = data.overview_extended

    # generate content data
    for object in data.objects

      # check if info for each col. is already there
      for row in dataTypesForCols

        # lookup relation
        if !object[row.name]
          rowWithoutId = row.name + '_id'
          for attribute in attributes
            if rowWithoutId is attribute.name
              if attribute.relation && App[attribute.relation]
                record = App.Collection.find( attribute.relation, object[rowWithoutId] )
                object[row.name] = record.name

    @log 'table', 'header', header, 'overview', dataTypesForCols, 'objects', data.objects
    table = App.view('generic/table')(
      header:   header
      overview: dataTypesForCols
      objects:  data.objects
      checkbox: data.checkbox
      radio:    data.radio
      groupBy:  data.groupBy
    )

    # convert to jquery object
    table = $(table)

    # enable checkbox bulk selection
    if data.checkbox
      table.delegate('[name="bulk_all"]', 'click', (e) ->
        if $(e.target).attr('checked')
          $(e.target).parents().find('[name="bulk"]').attr( 'checked', true );
        else
          $(e.target).parents().find('[name="bulk"]').attr( 'checked', false );
      )

    return table