class App.FormHandlerAdminCoreWorkflow
  @run: (params, attribute, attributes, classname, form, ui) ->
    return if attribute.name isnt 'object'

    return if ui.FormHandlerAdminCoreWorkflowDone
    ui.FormHandlerAdminCoreWorkflowDone = true

    $(form).find('select[name=object]').off('change.core_workflow_conditions').on('change.change.core_workflow_conditions', (e) ->
      for attribute in attributes
        continue if attribute.name isnt 'condition_saved' && attribute.name isnt 'condition_selected' && attribute.name isnt 'perform'

        attribute.workflow_object = $(e.target).val()
        newElement = ui.formGenItem(attribute, classname, form)
        form.find('div.form-group[data-attribute-name="' + attribute.name + '"]').replaceWith(newElement)
    )
