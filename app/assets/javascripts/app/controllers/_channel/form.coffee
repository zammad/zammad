# coffeelint: disable=no_unnecessary_double_quotes
class ChannelForm extends App.ControllerSubContent
  requiredPermission: 'admin.channel_formular'
  header: 'Form'
  events:
    'change form.js-paramsDesigner': 'updateParamsDesigner'
    'keyup form.js-paramsDesigner': 'updateParamsDesigner'
    'change .js-formSetting input': 'toggleFormSetting'
    'change .js-paramsSetting select': 'updateGroup'

  elements:
    '.js-code': 'code'
    '.js-paramsSetting': 'paramsSetting'
    '.js-formSetting input': 'formSetting'

  constructor: ->
    super
    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>
    setting = App.Setting.get('form_ticket_create')

    element = $(App.view('channel/form')(
      baseurl: window.location.origin
      formSetting: setting
    ))

    group_id = App.Setting.get('form_ticket_create_group_id')
    selection = App.UiElement.select.render(
      name: 'group_id'
      multiple: false
      null: false
      relation: 'Group'
      nulloption: false
      value: group_id
      #class: 'form-control--small'
    )
    element.find('.js-groupSelector').html(selection)

    @html element

    @code.each (i, block) ->
      hljs.highlightBlock block

    @updateParamsDesigner()

  updateParamsDesigner: ->
    quote = (string) ->
      string = string.replace('\'', '\\\'')
        .replace(/\</g, '&lt;')
        .replace(/\>/g, '&gt;')
    params = @formParam(@$('.js-paramsDesigner'))
    paramString = ''
    for key, value of params
      if !_.isEmpty(value)
        if paramString != ''
          paramString += ",\n"
        if value == 'true' || value == 'false'
          paramString += "    #{key}: #{value}"
        else
          paramString += "    #{key}: '#{quote(value)}'"
    @$('.js-modal-params').html(paramString)

    # rebuild preview
    params.test = true
    if params.modal
      @$('.js-modal').removeClass('hide')
      @$('.js-inlineForm').addClass('hide')
      @$('.js-formInline').addClass('hide')
      @$('.js-formBtn').removeClass('hide')
      @$('.js-formBtn').ZammadForm(params)
      @$('.js-formBtn').text('Feedback')
    else
      @$('.js-modal').addClass('hide')
      @$('.js-inlineForm').removeClass('hide')
      @$('.js-formBtn').addClass('hide')
      @$('.js-formInline').removeClass('hide')
      @$('.js-formInline').ZammadForm(params)

  toggleFormSetting: =>
    value = @formSetting.prop('checked')
    App.Setting.set('form_ticket_create', value)

  updateGroup: =>
    value = @paramsSetting.find('[name=group_id]').val()
    App.Setting.set('form_ticket_create_group_id', value)

App.Config.set('Form', { prio: 2000, name: 'Form', parent: '#channels', target: '#channels/form', controller: ChannelForm, permission: ['admin.channel_formular'] }, 'NavBarAdmin')
