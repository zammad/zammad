# coffeelint: disable=camel_case_classes
class App.UiElement.core_workflow_condition extends App.UiElement.ApplicationSelector
  @defaults: (attribute = {}, params = {}) ->
    defaults = []

    groups =
      ticket:
        name: 'Ticket'
        model: 'Ticket'
        model_show: ['Ticket']
      group:
        name: 'Group'
        model: 'Group'
        model_show: ['Group']
      user:
        name: 'User'
        model: 'User'
        model_show: ['User']
      customer:
        name: 'Customer'
        model: 'User'
        model_show: ['Ticket']
      organization:
        name: 'Organization'
        model: 'Organization'
        model_show: ['User', 'Organization']
      'customer.organization':
        name: 'Organization'
        model: 'Organization'
        model_show: ['Ticket']
      session:
        name: 'Session'
        model: 'User'
        model_show: ['Ticket']

    showCustomModules = @coreWorkflowCustomModulesActive()
    if showCustomModules
      groups['custom'] =
        name: 'Custom'
        model_show: ['Ticket', 'User', 'Organization', 'Sla']

    currentObject = params.object
    if attribute.workflow_object isnt undefined
      currentObject = attribute.workflow_object

    if !_.isEmpty(currentObject)
      for key, data of groups
        continue if _.contains(data.model_show, currentObject)
        delete groups[key]

    operatorsType =
      'active$': ['is']
      'boolean$': ['is', 'is not', 'is set', 'not set']
      'integer$': ['is', 'is not', 'is set', 'not set']
      '^select$': ['is', 'is not', 'is set', 'not set']
      '^tree_select$': ['is', 'is not', 'is set', 'not set']
      '^(input|textarea|richtext)$': ['is', 'is not', 'is set', 'not set', 'regex match', 'regex mismatch']

    operatorsName =
      '_id$': ['is', 'is not', 'is set', 'not set']
      '_ids$': ['is', 'is not', 'is set', 'not set']

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
          display: 'Module',
          tag: 'select',
          multiple: true,
          options: options,
          null: false,
          operator: ['match one module', 'match all modules', 'match no modules']
        }
        continue
      if groupKey is 'session'
        elements['session.role_ids'] = {
          name: 'role_ids',
          display: 'Role',
          tag: 'select',
          relation: 'Role',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.group_ids_read'] = {
          name: 'group_ids_read',
          display: 'Group (read)',
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.group_ids_create'] = {
          name: 'group_ids_create',
          display: 'Group (create)',
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.group_ids_change'] = {
          name: 'group_ids_change',
          display: 'Group (change)',
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.group_ids_overview'] = {
          name: 'group_ids_overview',
          display: 'Group (overview)',
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.group_ids_full'] = {
          name: 'group_ids_full',
          display: 'Group (full)',
          tag: 'select',
          relation: 'Group',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }
        elements['session.permission_ids'] = {
          name: 'permission_ids',
          display: 'Permissions',
          tag: 'select',
          relation: 'Permission',
          null: false,
          operator: ['is', 'is not'],
          multiple: true
        }

      for row in App[groupMeta.model].configure_attributes
        continue if !_.contains(['input', 'textarea', 'richtext', 'select', 'integer', 'boolean', 'active', 'tree_select', 'autocompletion_ajax'], row.tag)
        continue if groupKey is 'ticket' && _.contains(['number', 'title'], row.name)

        # ignore passwords and relations
        if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids' && row.searchable isnt false
          config = _.clone(row)
          if config.tag is 'select'
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

    if _.contains(['is set', 'not set'], currentOperator)
      elementRow.find('.js-value').addClass('hide').html('<input type="hidden" name="' + name + '" value="true" />')
      return

    super(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @HasPreCondition: ->
    return false

  @hasEmptySelectorAtStart: ->
    return true
