# coffeelint: disable=camel_case_classes
class App.UiElement.core_workflow_perform extends App.UiElement.ApplicationSelector
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
      customer:
        name: 'Customer'
        model: 'User'
        model_show: ['User']
      organization:
        name: 'Organization'
        model: 'Organization'
        model_show: ['Organization']

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
      'boolean$': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option', 'set_fixed_to']
      'integer$': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly']
      '^date': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly']
      '^select$': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option', 'set_fixed_to', 'select', 'auto_select']
      '^tree_select$': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option', 'set_fixed_to', 'select', 'auto_select']
      '^input$': ['show', 'hide', 'remove', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'fill_in', 'fill_in_empty']

    operatorsName =
      '_id$': ['show', 'hide', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option', 'set_fixed_to', 'select', 'auto_select']
      '_ids$': ['show', 'hide', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly']
      'organization_id$': ['show', 'hide', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option']
      'owner_id$': ['show', 'hide', 'set_mandatory', 'set_optional', 'set_readonly', 'unset_readonly', 'add_option', 'remove_option', 'select', 'auto_select']

    # merge config
    elements = {}

    for groupKey, groupMeta of groups
      if groupKey is 'custom'
        continue if !showCustomModules

        options = {}
        for module in App.CoreWorkflowCustomModule.all()
          options[module.name] = module.name
        elements['custom.module'] = { name: 'module', display: 'Module', tag: 'select', multiple: true, options: options, null: false, operator: ['execute'] }
        continue

      for row in App[groupMeta.model].configure_attributes
        continue if !_.contains(['input', 'select', 'integer', 'boolean', 'tree_select', 'date', 'datetime'], row.tag)
        continue if _.contains(['created_at', 'updated_at'], row.name)
        continue if groupKey is 'ticket' && _.contains(['number', 'organization_id', 'title', 'escalation_at', 'first_response_escalation_at', 'update_escalation_at', 'close_escalation_at', 'last_contact_at', 'last_contact_agent_at', 'last_contact_customer_at', 'first_response_at', 'close_at'], row.name)

        # ignore passwords and relations
        if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids' && row.searchable isnt false
          config = _.clone(row)
          if config.tag is 'boolean'
            config.tag = 'select'
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

  @renderParamValue: (item, attribute, params, paramValue) ->
    [defaults, groups, elements] = @defaults(attribute, params)

    for groupAndAttribute, meta of paramValue

      if !_.isArray(meta.operator)
        meta.operator = [meta.operator]

      for operator in meta.operator
        operatorMeta = {}
        operatorMeta['operator'] = operator
        operatorMeta[operator] = meta[operator]

        # build and append
        row = @rowContainer(groups, elements, attribute)
        @rebuildAttributeSelectors(item, row, groupAndAttribute, elements, operatorMeta, attribute)
        item.filter('.js-filter').append(row)

  @buildValueConfigValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    return _.clone(attribute.value[groupAndAttribute][currentOperator])

  @buildValueName: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    return "#{attribute.name}::#{groupAndAttribute}::#{currentOperator}"

  @buildValue: (elementFull, elementRow, groupAndAttribute, elements, meta, attribute) ->
    currentOperator = elementRow.find('.js-operator option:selected').attr('value')
    name            = @buildValueName(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

    if !_.contains(['add_option', 'remove_option', 'set_fixed_to', 'select', 'execute', 'fill_in', 'fill_in_empty'], currentOperator)
      elementRow.find('.js-value').addClass('hide').html('<input type="hidden" name="' + name + '" value="true" />')
      return

    super(elementFull, elementRow, groupAndAttribute, elements, meta, attribute)

  @buildValueConfigMultiple: (config, meta) ->
    if _.contains(['add_option', 'remove_option', 'set_fixed_to'], meta.operator)
      config.multiple = true
      config.nulloption = true
    else
      config.multiple = false
      config.nulloption = false
    return config

  @HasPreCondition: ->
    return false

  @hasEmptySelectorAtStart: ->
    return true

  @hasDuplicateSelector: ->
    return true
