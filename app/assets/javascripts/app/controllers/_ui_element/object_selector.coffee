# coffeelint: disable=camel_case_classes
class App.UiElement.object_selector extends App.UiElement.ApplicationSelectorExpert
  @defaults: (attribute = {}, params = {}) =>
    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
        model_show: ['Ticket']
      article:
        name: __('Article')
        model: 'TicketArticle'
        model_show: ['Ticket']
      customer:
        name: __('Customer')
        model: 'User'
        model_show: ['Ticket']
      user:
        name: __('User')
        model: 'User'
        model_show: ['User']
      ticket_customer:
        name: __('Ticket Customer')
        model_show: ['User']
      ticket_owner:
        name: __('Ticket Owner')
        model_show: ['User']
      organization:
        name: __('Organization')
        model: 'Organization'
        model_show: ['Ticket', 'User', 'Organization']

    if attribute.executionTime
      groups.execution_time =
        name: __('Execution Time')
        model_show: ['Ticket']

    if attribute.object_name is undefined
      attribute.object_name = params.object or 'Ticket'

    defaults = []

    switch attribute.object_name
      when 'Ticket' then defaults.push 'ticket.state_id'
      when 'User' then defaults.push 'user.role_ids'
      when 'Organization' then defaults.push 'organization.members_existing'

    for key, data of groups
      continue if _.contains(data.model_show, attribute.object_name)
      delete groups[key]

    operators_type =
      '^datetime$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^timestamp$': [__('today'), __('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)')]
      '^date$': [__('today'), 'before (absolute)', 'after (absolute)', 'before (relative)', 'after (relative)', 'within next (relative)', 'within last (relative)']
      'boolean$': [__('is'), __('is not')]
      'integer$': [__('is'), __('is not'), __('is less than'), __('is greater than')]
      '^radio$': [__('is'), __('is not')]
      '^select$': [__('is'), __('is not')]
      '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^tree_select$': [__('is'), __('is not')]
      '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
      '^autocompletion_ajax_external_data_source$': [__('is'), __('is not')]
      '^input$': [__('contains'), __('contains not'), __('is any of'), __('is none of'), __('starts with one of'), __('ends with one of')]
      '^richtext$': [__('contains'), __('contains not')]
      '^textarea$': [__('contains'), __('contains not')]
      '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    if attribute.hasChanged
      operators_type =
        '^datetime$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^timestamp$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        '^date$': [__('before (absolute)'), __('after (absolute)'), __('before (relative)'), __('after (relative)'), __('within next (relative)'), __('within last (relative)'), __('till (relative)'), __('from (relative)'), __('has changed')]
        'boolean$': [__('is'), __('is not'), __('has changed')]
        'integer$': [__('is'), __('is not'), __('has changed'), __('is less than'), __('is greater than')]
        '^radio$': [__('is'), __('is not'), __('has changed')]
        '^select$': [__('is'), __('is not'), __('has changed')]
        '^multiselect$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^tree_select$': [__('is'), __('is not'), __('has changed')]
        '^multi_tree_select$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]
        '^autocompletion_ajax_external_data_source$': [__('is'), __('is not'), __('has changed')]
        '^input$': [__('contains'), __('contains not'), __('has changed'), __('is any of'), __('is none of'), __('starts with one of'), __('ends with one of')]
        '^richtext$': [__('contains'), __('contains not'), __('has changed')]
        '^textarea$': [__('contains'), __('contains not'), __('has changed')]
        '^tag$': [__('contains all'), __('contains one'), __('contains all not'), __('contains one not')]

    if attribute.hasRegexOperators && App.Config.get('ticket_conditions_allow_regular_expression_operators')
      operators_type['^input$'].push(__('matches regex'), __('does not match regex'))

    operators_name =
      '_id$': [__('is'), __('is not')]
      '_ids$': [__('is'), __('is not')]
      'active$': [__('is'), __('is not')]

    if attribute.hasChanged
      operators_name =
        '_id$': [__('is'), __('is not'), __('has changed')]
        '_ids$': [__('is'), __('is not'), __('has changed')]
        'active$': [__('is'), __('is not'), __('has changed')]

    # merge config
    elements = {}

    if attribute.article is false
      delete groups.article

    if attribute.object_name is 'Ticket' and attribute.action
      elements['ticket.action'] =
        name: 'action'
        display: __('Action')
        tag: 'select'
        null: false
        translate: true
        options:
          create:                  __('created')
          update:                  __('updated')
          'update.merged_into':    __('merged into')
          'update.received_merge': __('received merge')
        operator: [__('is'), __('is not')]

    for groupKey, groupMeta of groups
      if groupKey is 'article'
        if attribute.action
          elements['article.action'] =
            name: 'action'
            display: __('Action')
            tag: 'select'
            null: false
            translate: true
            options:
              create: 'created'
            operator: [__('is'), __('is not')]
          elements['article.time_accounting'] =
            name: 'time_accounting'
            display: __('Time Accounting')
            tag: 'select'
            null: false
            translate: true
            options:
              create: 'created'
            operator: [__('is set'), __('not set')]

      if groupKey is 'execution_time'
        if attribute.executionTime
          elements['execution_time.calendar_id'] =
            name: 'calendar_id'
            display: __('Calendar')
            tag: 'select'
            relation: 'Calendar'
            null: false
            translate: false
            operator: [__('is in working time'), __('is not in working time')]

      else
        attributesByObject = App.ObjectManagerAttribute.selectorAttributesByObject()
        configureAttributes = attributesByObject[groupMeta.model] || []
        for config in configureAttributes
          config.objectName    = groupMeta.model
          config.attributeName = config.name

          # ignore passwords and relations
          if config.type isnt 'password' && config.name.substr(config.name.length-4,4) isnt '_ids' && config.searchable isnt false
            config.default  = undefined
            if config.type is 'email' || config.type is 'tel' || config.type is 'url'
              config.type = 'text'
            if config.tag is 'select' or config.tag is 'autocompletion_ajax_external_data_source'
              config.multiple = true
            for operatorRegEx, operator of operators_type
              myRegExp = new RegExp(operatorRegEx, 'i')
              if config.tag && config.tag.match(myRegExp)
                config.operator = operator
              elements["#{groupKey}.#{config.name}"] = config
            for operatorRegEx, operator of operators_name
              myRegExp = new RegExp(operatorRegEx, 'i')
              if config.name && config.name.match(myRegExp)
                config.operator = operator
              elements["#{groupKey}.#{config.name}"] = config

    if attribute.object_name is 'Ticket' and attribute.hasReached
      [
        'ticket.pending_time',
        'ticket.escalation_at',
      ].forEach (element_name) ->
        new_operator = clone(elements[element_name]['operator'])
        new_operator.push(__('has reached'))
        if element_name == 'ticket.escalation_at'
          new_operator.push(__('has reached warning'))
        elements[element_name]['operator'] = new_operator

    if attribute.object_name is 'Ticket' and attribute.out_of_office
      elements['ticket.out_of_office_replacement_id'] =
        name: 'out_of_office_replacement_id'
        display: __('Out of office replacement')
        tag: 'autocompletion_ajax'
        relation: 'User'
        null: false
        translate: true
        operator: [__('is'), __('is not')]

    # Remove 'has changed' operator from attributes which don't support the operator.
    ["#{@objectKey(attribute.object_name)}.created_at", "#{@objectKey(attribute.object_name)}.updated_at"].forEach (element_name) ->
      elements[element_name]['operator'] = elements[element_name]['operator'].filter (item) -> item != 'has changed'

    if attribute.object_name is 'Ticket'
      elements['ticket.mention_user_ids'] =
        name: 'mention_user_ids'
        display: __('Subscribe')
        tag: 'autocompletion_ajax'
        relation: 'User'
        null: false
        translate: true
        operator: [__('is'), __('is not')]

    if attribute.object_name is 'User'
      elements['user.role_ids'] =
        name: 'role_ids'
        display: __('Role')
        tag: 'select'
        relation: 'Role'
        null: false
        operator: [__('is'), __('is not')]
        multiple: true
      elements['user.last_login'] =
          name: 'last_login'
          display: __('Last login')
          tag: 'datetime'
          null: false
          operator: operators_type['^datetime$']

      [
        {
          name: 'last_contact_at',
          display: __('Last contact')
        },
        {
          name: 'last_contact_agent_at',
          display: __('Last contact (agent)')
        },
        {
          name: 'last_contact_customer_at'
          display: __('Last contact (customer)')
        },
        {
          name: 'updated_at'
          display: __('Updated at')
        },
      ].forEach (attr) ->
        elements["ticket_customer.#{attr.name}"] =
          name: attr.name
          display: attr.display
          tag: 'datetime'
          null: false
          operator: operators_type['^datetime$']

      [
        {
          name: 'existing'
          display: __('Existing tickets')
          group: 'ticket_customer'
        },
        {
          name: 'open_existing',
          display: __('Existing tickets (open)'),
          group: 'ticket_customer'
        },
        {
          name: 'existing'
          display: __('Existing tickets')
          group: 'ticket_owner'
        },
        {
          name: 'open_existing',
          display: __('Existing tickets (open)'),
          group: 'ticket_owner'
        },
      ].forEach (attr) ->
        elements["#{attr.group}.#{attr.name}"] =
          name: attr.name
          display: attr.display
          tag: 'boolean'
          operator: [__('is'), __('is not')]

    if attribute.object_name is 'Organization'
      elements['organization.members_existing'] =
        name: 'members_existing'
        display: __('Existing members')
        tag: 'boolean'
        operator: [__('is'), __('is not')]

    [defaults, groups, elements]

  @objectKey: (objectName) ->
    objectName.toLowerCase()

  @render: (attribute, params = {}) ->
    @defaults(attribute, params)

    super

  @renderItem: (item, attribute, params) ->

    # NB: Store object name in the jQuery instance so it can be re-used by other functions.
    #   All methods in this class are called in a static fashion!
    #   We cannot rely on instance variables for that reason.
    item.data('objectName', attribute.object_name)
      .attr('data-object-name', attribute.object_name)

    super

  @preview: (item) ->
    params = App.ControllerForm.params(item)
    object_name = item.data('objectName')

    App.Ajax.request(
      id:    'application_selector'
      type:  'POST'
      url:   "#{App[object_name].url}/selector"
      data:        JSON.stringify(params)
      processData: true,
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        item.find('.js-previewCounterContainer').removeClass('hide')
        item.find('.js-previewLoader').addClass('hide')
        if object_name is 'Ticket'
          @ticketTable(data.object_ids, data.object_count, item)
        else
          @previewTable(object_name, data.object_ids, data.object_count, item)
    )

  @previewTable: (object_name, object_ids, object_count, item) ->
    item.find('.js-previewCounter').html(object_count)
    new App.PreviewList(
      tableId:     'object-selector'
      el:          item.find('.js-previewTable')
      object_name: object_name
      object_ids:  object_ids
    )
