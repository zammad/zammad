class App.FormHandlerAIAgentUnusedWarning
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'active'

    return if ui.FormHandlerAIAgentUnusedWarningDone
    ui.FormHandlerAIAgentUnusedWarningDone = true

    $(form).find('select[name=active]').off('change.unused_warning').on('change.unused_warning', (e) ->
      is_active = $(e.target).val() is 'true'

      if _.isEmpty(ui.params.references) and is_active
        setTimeout ->
          $('<div />').addClass('alert alert--warning js-unusedWarning')
            .html(App.i18n.translateContent('For this agent to run, it needs to be used in an automation (e.g. trigger, scheduler, macro).'))
            .insertBefore($(form))
        , 0
      else
        $(form).parent()
          .find('.js-unusedWarning')
          .remove()

    ).trigger('change.unused_warning')
