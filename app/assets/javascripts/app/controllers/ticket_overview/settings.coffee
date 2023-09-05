class App.TicketOverviewSettings extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  headPrefix: 'Edit'

  content: =>
    @overview = App.Overview.find(@overview_id)
    @head     = @overview.name

    @configure_attributes_article = []
    if @view_mode is 'd'
      @configure_attributes_article.push({
        name:     'view::per_page'
        display:  __('Items per page')
        tag:      'select'
        multiple: false
        null:     false
        default: @overview.view.per_page
        options: {
          5: ' 5'
          10: '10'
          15: '15'
          20: '20'
          25: '25'
        },
      })

    @configure_attributes_article.push({
      name:      "view::#{@view_mode}"
      display:   __('Attributes')
      tag:       'checkboxTicketAttributes'
      default:   @overview.view[@view_mode]
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::by'
      display:   __('Sorting by')
      tag:       'selectTicketAttributes'
      default:   @overview.order.by
      null:      false
      translate: true
      sortBy:    null
    },
    {
      name:      'order::direction'
      display:   __('Sorting order')
      tag:       'select'
      default:   @overview.order.direction
      null:      false
      translate: true
      options:
        ASC:  __('ascending')
        DESC: __('descending')
    },
    {
      name:       'group_by'
      display:    __('Grouping by')
      tag:        'select'
      default:    @overview.group_by
      null:       true
      nulloption: true
      translate:  true
      options:    App.Overview.groupByAttributes()
    },
    {
      name:    'group_direction'
      display: __('Grouping order')
      tag:     'select'
      default: @overview.group_direction
      null:    false
      translate: true
      options:
        ASC:   __('ascending')
        DESC:  __('descending')
    },)

    controller = new App.ControllerForm(
      model:     { configure_attributes: @configure_attributes_article }
      autofocus: false
    )
    controller.form

  onClose: =>
    if @onCloseCallback
      @onCloseCallback()

  onSubmit: (e) =>
    params = @formParam(e.target)

    # check if re-fetch is needed
    @reload_needed = false
    if @overview.order.by isnt params.order.by
      @overview.order.by = params.order.by
      @reload_needed = true

    if @overview.order.direction isnt params.order.direction
      @overview.order.direction = params.order.direction
      @reload_needed = true

    if @overview.group_direction isnt params.group_direction
      @overview.group_direction = params.group_direction
      @reload_needed = true

    for key, value of params.view
      @overview.view[key] = value

    @overview.group_by = params.group_by

    @overview.save(
      done: =>

        # fetch overview data again
        if @reload_needed
          App.OverviewListCollection.fetch(@overview.link)
        else
          App.OverviewIndexCollection.trigger()
          App.OverviewListCollection.trigger(@overview.link)

        # close modal
        @close()
    )
