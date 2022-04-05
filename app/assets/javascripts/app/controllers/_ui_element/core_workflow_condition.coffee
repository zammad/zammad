# coffeelint: disable=camel_case_classes
class App.UiElement.core_workflow_condition extends App.UiElement.ApplicationSelector
  @defaults: (attribute = {}, params = {}) ->
    defaults = []

    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
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
        model_show: ['Ticket']

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

    operatorsType =
      'active$': [__('is')]
      'boolean$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      'integer$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      '^select$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      '^multiselect$': [__('contains'), __('contains not'), __('contains all'), __('contains all not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      '^tree_select$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      '^(input|textarea|richtext)$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to'), __('regex match'), __('regex mismatch')]

    operatorsName =
      '_id$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]
      '_ids$': [__('is'), __('is not'), __('is set'), __('not set'), __('has changed'), __('changed to')]

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

      for row in App[groupMeta.model].configure_attributes
        continue if !_.contains(['input', 'textarea', 'richtext', 'multiselect', 'select', 'integer', 'boolean', 'active', 'tree_select', 'autocompletion_ajax'], row.tag)
        continue if groupKey is 'ticket' && _.contains(['number', 'title'], row.name)

        # ignore passwords and relations
        if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids' && row.searchable isnt false
          config = _.clone(row)
          if config.tag is 'textarea'
            config.expanding = false
          if /^((multi)?select)$/.test(config.tag)
            config.multiple = true
            config.default  = undefined
          if config.type is 'email' || config.type is 'tel'
            config.type = 'text'
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

    [defaults, groups, elements]

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    name            = @buildValueName(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    if _.contains(['is set', 'not set', 'has changed'], currentOperator)
      elementRow.find('.js-value').addClass('hide').html('<input type="hidden" name="' + name + '" value="true" />')
      return

    super(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @HasPreCondition: ->
    return false

  @hasEmptySelectorAtStart: ->
    return true
