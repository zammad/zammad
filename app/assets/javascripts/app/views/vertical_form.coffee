class App.KnowledgeBaseVerticalForm extends App.Controller
  elements:
    '.form-item': 'container'

  constructor: ->
    super
    @form.form.addClass('controls')
    @render()

  render: ->
    attribute_identifier = @form.attributes[0].name

    attribute = _.find(
      App.Model.attributesGet(false, @form.model.configure_attributes),
      (elem) ->
        elem.name == attribute_identifier
    )

    @html App.view('knowledge_base/vertical_form')(
      attribute: attribute
    )

    @container.html @form.form
