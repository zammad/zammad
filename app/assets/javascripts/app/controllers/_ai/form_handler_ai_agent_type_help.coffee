class App.FormHandlerAIAgentTypeHelp
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'agent_type'

    return if ui.FormHandlerAIAgentTypeHelpDone
    ui.FormHandlerAIAgentTypeHelpDone = true

    $(form).find('select[name=agent_type]').off('change.agent_type').on('change.agent_type', (e) ->
      agent_type = $(e.target).val()
      description = App.AIAgentType.find(agent_type)?.description

      $(form).find('select[name=agent_type]')
        .closest('.form-group')
        .find('.help-block')
        .html(App.i18n.translateContent(description))
    ).trigger('change.agent_type')
