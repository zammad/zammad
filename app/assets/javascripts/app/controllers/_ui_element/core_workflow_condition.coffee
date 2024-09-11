# coffeelint: disable=camel_case_classes
class App.UiElement.core_workflow_condition extends App.UiElement.ApplicationSelector
  @defaults: (attribute = {}, params = {}) ->
    attribute.noNotSet = true

    defaults = []
    if !@hasEmptySelectorAtStart()
      defaults = ['ticket.state_id']

    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
        model_show: ['Ticket']
      article:
        name: __('Article')
        model: 'TicketArticle'
        model_show: ['Ticket']
      group:
        name: __('Group')
        model: 'Group'
        model_show: ['Group']
      user:
        name: __('User')
        model: 'User'
        model_show: ['User']
      customer:
        name: __('Customer')
        model: 'User'
        model_show: ['Ticket']
      organization:
        name: __('Organization')
        model: 'Organization'
        model_show: ['User', 'Organization']
      'customer.organization':
        name: __('Organization')
        model: 'Organization'
        model_show: ['Ticket']
      session:
        name: __('Session')
        model: 'User'
        model_show: ['Ticket', 'Group', 'User', 'Organization']

    showCustomModules = @coreWorkflowCustomModulesActive()
    if showCustomModules
      groups['custom'] =
        name: __('Custom')
        model_show: ['Ticket', 'User', 'Organization', 'Sla']

    currentObject = params.object
    if attribute.workflow_object isnt undefined
      currentObject = attribute.workflow_object

    if !_.isEmpty(currentObject)
      for key, data of groups
        continue if _.contains(data.model_show, currentObject)
        delete groups[key]

    if attribute.disable_objects
      for key in attribute.disable_objects
        delete groups[key]

    operatorsType =
      '^datetime$': [
        __('today'),
        __('before (absolute)'),
        __('after (absolute)'),
        __('before (relative)'),
        __('after (relative)'),
        __('within next (relative)'),
        __('within last (relative)'),
        __('till (relative)'),
        __('from (relative)')
      ]
      '^timestamp$': [
        __('today'),
        __('before (absolute)'),
        __('after (absolute)'),
        __('before (relative)'),
        __('after (relative)'),
        __('within next (relative)'),
        __('within last (relative)'),
        __('till (relative)'),
        __('from (relative)')
      ]
      '^date$': [
        __('today'),
        __('before (absolute)'),
        __('after (absolute)'),
        __('before (relative)'),
        __('after (relative)'),
        __('within next (relative)'),
        __('within last (relative)')
      ]
      'active$': [
        __('is')
      ]
      'boolean$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      'integer$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      'radio$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^select$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^multiselect$': [
        __('contains'),
        __('contains not'),
        __('contains all'),
        __('contains all not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^tree_select$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
        ]
      '^multi_tree_select$': [
        __('contains'),
        __('contains not'),
        __('contains all'),
        __('contains all not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^autocompletion_ajax_external_data_source$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^input$': [
        __('is any of'),
        __('is none of'),
        __('starts with one of'),
        __('ends with one of'),
        __('matches regex'),
        __('does not match regex'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^(textarea|richtext)$': [
        __('is'),
        __('is not'),
        __('starts with'),
        __('ends with'),
        __('matches regex'),
        __('does not match regex'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '^tag$': [
        __('contains all'),
        __('contains one'),
        __('contains all not'),
        __('contains one not')
      ]

    operatorsName =
      '_id$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      '_ids$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]
      'active$': [
        __('is'),
        __('is not'),
        __('is set'),
        __('not set'),
        __('is modified'),
        __('is modified to'),
        __('just changed'),
        __('just changed to')
      ]

    if attribute.disable_operators
      for key, value of operatorsType
        operatorsType[key] = _.filter(value, (v) -> !_.contains(attribute.disable_operators, v))
      for key, value of operatorsName
        operatorsName[key] = _.filter(value, (v) -> !_.contains(attribute.disable_operators, v))

    # merge config
    elements = {}

    for groupKey, groupMeta of groups
      if groupKey is 'custom'
        continue if !showCustomModules

        options = {}
        for module in App.CoreWorkflowCustomModule.all()
          options[module.name] = module.name

        elements['custom.module'] = {
          name: 'module',
          display: __('Module'),
          tag: 'select',
          multiple: true,
          options: options,
          null: false,
          operator: [__('match one module'), __('match all modules'), __('match no modules')]
        }
        continue
      if groupKey is 'session'
        elements['session.role_ids'] = {
          name: 'role_ids',
          display: __('Role'),
          tag: 'select',
          relation: 'Role',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.group_ids_read'] = {
          name: 'group_ids_read',
          display: __('Group (read)'),
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.group_ids_create'] = {
          name: 'group_ids_create',
          display: __('Group (create)'),
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.group_ids_change'] = {
          name: 'group_ids_change',
          display: __('Group (change)'),
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.group_ids_overview'] = {
          name: 'group_ids_overview',
          display: __('Group (overview)'),
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.group_ids_full'] = {
          name: 'group_ids_full',
          display: __('Group (full)'),
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }
        elements['session.permission_ids'] = {
          name: 'permission_ids',
          display: __('Permissions'),
          tag: 'select',
          relation: 'Permission',
          null: false,
          operator: [__('is'), __('is not')],
          multiple: true
        }

      attributesByObject = App.ObjectManagerAttribute.selectorAttributesByObject()
      configureAttributes = attributesByObject[groupMeta.model] || []
      for config in configureAttributes
        continue if groupKey is 'group' && _.contains(['name'], config.name)

        config.objectName    = groupMeta.model
        config.attributeName = config.name

        # ignore passwords and relations
        if config.type isnt 'password' && config.name.substr(config.name.length-4,4) isnt '_ids' && config.searchable isnt false
          config.default  = undefined
          if config.type is 'email' || config.type is 'tel' || config.type is 'url'
            config.type = 'text'
          if config.tag && config.tag.match(/^(tree_)?select$/) or config.tag is 'autocompletion_ajax_external_data_source'
            config.multiple = true
          for operatorRegEx, operator of operatorsType
            myRegExp = new RegExp(operatorRegEx, 'i')
            if config.tag && config.tag.match(myRegExp)
              config.operator = operator
            elements["#{groupKey}.#{config.name}"] = config
          for operatorRegEx, operator of operatorsName
            myRegExp = new RegExp(operatorRegEx, 'i')
            if config.name && config.name.match(myRegExp)
              config.operator = operator
            elements["#{groupKey}.#{config.name}"] = config

    elements['ticket.mention_user_ids'] =
      name: 'mention_user_ids'
      display: __('Subscribe')
      tag: 'autocompletion_ajax'
      relation: 'User'
      null: false
      translate: true
      operator: [__('is'), __('is not')]

    [defaults, groups, elements]

  @hasEmptySelectorAtStart: ->
    return true
