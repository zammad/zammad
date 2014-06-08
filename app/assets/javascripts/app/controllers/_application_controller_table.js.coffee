class App.ControllerTable extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value

    @table = @tableGen(params)
    if @el
      @el.append( @table )

  ###

    new App.ControllerTable(
      header:   ['Host', 'User', 'Adapter', 'Active']
      overview: ['host', 'user', 'adapter', 'active']
      model:    App.Channel
      objects:  data
      checkbox: false
      radio:    false
    )

    new App.ControllerTable(
      overview_extended: [
        { name: 'number',                 link: true }
        { name: 'title',                  link: true }
        { name: 'customer',               class: 'user-popover', data: { id: true } }
        { name: 'state',                  translate: true }
        { name: 'priority',               translate: true }
        { name: 'group' },
        { name: 'owner',                  class: 'user-popover', data: { id: true } }
        { name: 'created_at',             callback: @frontendTime }
        { name: 'last_contact',           callback: @frontendTime }
        { name: 'last_contact_agent',     callback: @frontendTime }
        { name: 'last_contact_customer',  callback: @frontendTime }
        { name: 'first_response',         callback: @frontendTime }
        { name: 'close_time',             callback: @frontendTime }
      ],
      model:    App.Ticket
      objects:  tickets
      checkbox: false
      radio:    false
    )

  ###

  tableGen: (data) ->
    overview   = data.overview || data.model.configure_overview || []
    attributes = data.attributes || data.model.configure_attributes || {}
    header     = data.header
    destroy    = data.model.configure_delete

    # check if table is empty
    if _.isEmpty(data.objects)
      table = '<p>-' + App.i18n.translateContent( 'none' ) + '-</p>'
      return $(table)

    # define table header
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
        found = false
        if attributes
          for attribute in attributes
            if row is attribute.name
              found = true
              header.push attribute
            else
              rowWithoutId = row + '_id'
              if rowWithoutId is attribute.name
                found = true
                header.push attribute
        if !found
          header.push {
            name:    row
            display: row
          }

    # collect data of col. types
    dataTypesForCols = []
    for row in overview

      if !_.isEmpty(attributes)
        for attribute in attributes
          found = false
          if row is attribute.name
            found = true
            dataTypesAttribute = _.clone(attribute)
          else if row + '_id' is attribute.name
            found = true
            dataTypesAttribute = _.clone(attribute)
            dataTypesAttribute['name'] = row
          if found
            dataTypesAttribute['type'] = 'link'
            if !dataTypesAttribute['dataType']
              dataTypesAttribute['dataType'] = 'edit'
            dataTypesForCols.push dataTypesAttribute
      else
        dataTypesForCols.push {
          name: row
          type: 'link'
          dataType: 'edit'
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
              if attribute.relation && App[ attribute.relation ]
                if App[ attribute.relation ].exists( object[rowWithoutId] )
                  record = App[ attribute.relation ].find( object[rowWithoutId] )
                  object[row.name] = record.name

    @log 'debug', 'table', 'header', header, 'overview', dataTypesForCols, 'objects', data.objects
    table = App.view('generic/table')(
      header:   header
      overview: dataTypesForCols
      objects:  data.objects
      checkbox: data.checkbox
      radio:    data.radio
      groupBy:  data.groupBy
      destroy:  destroy
    )

    # convert to jquery object
    table = $(table)

    # bind on delete dialog
    if data.model && destroy
      table.delegate('[data-type="destroy"]', 'click', (e) ->
        e.preventDefault()
        itemId = $(e.target).parents('tr').data('id')
        item   = data.model.find(itemId)
        new App.ControllerGenericDestroyConfirm(
          item: item
        )
      )

    # enable checkbox bulk selection
    if data.checkbox
      table.delegate('[name="bulk_all"]', 'click', (e) ->
        if $(e.target).prop('checked')
          $(e.target).parents().find('[name="bulk"]').prop( 'checked', true );
        else
          $(e.target).parents().find('[name="bulk"]').prop( 'checked', false );
      )

    return table
