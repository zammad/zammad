class App.ChannelEmailSignature extends App.Controller
  events:
    'click [data-type=new]':  'new'

  constructor: ->
    super
    App.Signature.subscribe(@render, initFetch: true)

  render: =>
    data = App.Signature.search(sortBy: 'name')

    template = $( '<div><div class="overview"></div><a data-type="new" class="btn btn--success">' + App.i18n.translateContent('New') + '</a></div>' )

    description = '''
You can define different signatures for each group. So you can have different email signatures for different departments.

Once you have created a signature here, you need also to edit the groups where you want to use it.
'''

    new App.ControllerTable(
      el:       template.find('.overview')
      model:    App.Signature
      objects:  data
      bindRow:
        events:
          'click': @edit
      explanation: description
    )
    @html template

  new: (e) =>
    e.preventDefault()
    new ChannelEmailSignatureEdit(
      container: @el.closest('.content')
    )

  edit: (id, e) =>
    e.preventDefault()
    item = App.Signature.find(id)
    new ChannelEmailSignatureEdit(
      object:    item
      container: @el.closest('.content')
    )

class ChannelEmailSignatureEdit extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: 'Signature'

  content: =>
    if @object
      @form = new App.ControllerForm(
        model:     App.Signature
        params:    @object
        autofocus: true
      )
    else
      @form = new App.ControllerForm(
        model:     App.Signature
        autofocus: true
      )

    @form.form

  onSubmit: (e) =>

    # get params
    params = @formParam(e.target)

    object = @object || new App.Signature
    object.load(params)

    # validate form
    errors = @form.validate(params)

    # show errors in form
    if errors
      @log 'error', errors
      @formValidate(form: e.target, errors: errors)
      return false

    # disable form
    @formDisable(e)

    # save object
    object.save(
      done: =>
        @close()
      fail: (settings, details) =>
        @log 'errors', details
        @formEnable(e)
        @form.showAlert(details.error_human || details.error || 'Unable to create object!')
    )
