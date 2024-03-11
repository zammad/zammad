class ChannelWhatsapp extends App.ControllerSubContent
  @requiredPermission: 'admin.channel_whatsapp'
  events:
    'click .js-new':     'new'
    'click .js-edit':    'edit'
    'click .js-delete':  'delete'
    'click .js-disable': 'disable'
    'click .js-enable':  'enable'

  constructor: ->
    super

    @load()

  load: =>
    @startLoading()
    @ajax(
      id: 'whatsapp_index'
      type: 'GET'
      url: "#{@apiPath}/channels/admin/whatsapp"
      processData: true
      success: (data) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @render(data)
    )

  render: (data) =>
    channels = data.channel_ids.map (elem) -> App.Channel.find(elem)

    @html App.view('whatsapp/index')(
      channels: channels
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'WhatsApp::Business'
    )

  new: (e) =>
    e.preventDefault()

    new WhatsappAccountCloudAPIModal(
      container: @el.parents('.content')
      load: @load
      headPrefix: __('New')
    )

  edit: (e) =>
    e.preventDefault()

    id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)

    new WhatsappAccountCloudAPIModal(
      container: @el.parents('.content')
      channel: channel
      load: @load
      headPrefix: __('Edit')
    )

  delete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')

    new App.ControllerConfirm(
      message:     __('Are you sure?')
      buttonClass: 'btn--danger'
      callback: =>
        @ajax(
          id:   'whatsapp_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels/admin/whatsapp/#{id}"
          processData: true
          success: =>
            @load()
        )
      container: @el.closest('.content')
    )

  disable: (e) =>
    e.preventDefault()

    id = $(e.target).closest('.action').data('id')

    @ajax(
      id:   'whatsapp_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/whatsapp/#{id}/disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()

    id = $(e.target).closest('.action').data('id')

    @ajax(
      id:   'whatsapp_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels/admin/whatsapp/#{id}/enable"
      processData: true
      success: =>
        @load()
    )

class WhatsappAccountCloudAPIModal extends App.ControllerModal
  head: __('WhatsApp Account')
  shown: true
  buttonSubmit: __('Next')
  buttonClass: 'btn--primary'
  buttonCancel: true
  small: true

  content: =>
    $(App.view('whatsapp/account_cloud_api')(
      channel: @channel
      params:  @params
    ))

  onSubmit: (e) =>
    element = $(e.target).closest('form').get(0)
    if element && element.reportValidity && !element.reportValidity()
      return false

    @clearAlerts()
    @formDisable(e)

    params = if @params then _.extend(@params, @formParams()) else @formParams()

    @ajax(
      id: 'whatsapp_initial'
      type: 'POST'
      url: "#{@apiPath}/channels/admin/whatsapp/preload"
      data: JSON.stringify(params)
      processData: true
      success: (data) =>
        @el.removeClass('fade')
        @close()

        params.available_phone_numbers = data.data.phone_numbers

        new WhatsappAccountPhoneNumberModal(
          params:     params
          channel:    @channel
          container:  @container
          load:       @load
          headPrefix: @headPrefix
        )
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(e)
        error_message = App.i18n.translateContent(data.error || __('The WhatsApp connection could not be saved.'))
        @showAlert(error_message)
    )

class WhatsappAccountPhoneNumberModal extends App.ControllerModal
  head: __('WhatsApp Account')
  shown: true
  buttonCancel: true
  small: true

  content: =>
    content = $(App.view('whatsapp/account_phone_number')(
      channel: @channel
      params:  @params
    ))

    preselected_group_id = if @channel then @channel.group_id else 1

    content.find('.js-reminderActive').replaceWith App.UiElement.switch.render(
      name: 'reminder_active'
      null: false
      default: true
      display: __('Automatic reminders')
      value: if _.isUndefined(@channel?.options?.reminder_active) then true else @channel.options.reminder_active
    )

    content.find('.js-messagesGroup').replaceWith App.UiElement.tree_select.render(
      name: 'group_id'
      multiple: false
      limit: 100
      null: false
      relation: 'Group'
      nulloption: true
      value: preselected_group_id
    )

    content.find('.js-phoneNumbers').replaceWith App.UiElement.select.render(
      name: 'phone_number_id'
      multiple: false
      value: @channel?.options?.phone_number_id || @params.available_phone_numbers?[0]?.value
      options: @params.available_phone_numbers?.map (elem) -> { name: elem.label, value: elem.value }
      rejectNonExistentValues: true
    )

    content

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    element = $(e.target).closest('form').get(0)
    if element && element.reportValidity && !element.reportValidity()
      return false

    @clearAlerts()

    if @channel
      url    =  "#{@apiPath}/channels/admin/whatsapp/#{@channel.id}"
      method = 'PUT'
    else
      url    = "#{@apiPath}/channels/admin/whatsapp"
      method = 'POST'

    @formDisable(e)

    params = @formParams()

    @ajax(
      id: 'whatsapp_save'
      type: method
      url: url
      data: JSON.stringify(params)
      processData: true
      success: (data) =>
        @isChanged = true
        @el.removeClass('fade')
        @close()

        new WhatsappAccountWebhookModal(
          channel:    data
          container:  @container
          headPrefix: @headPrefix
        )
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(e)
        error_message = App.i18n.translateContent(data.error || __('The WhatsApp connection could not be saved.'))
        @showAlert(error_message)
    )

class WhatsappAccountWebhookModal extends App.ControllerModal
  head: __('WhatsApp Account')
  shown: true
  buttonSubmit: __('Finish')
  buttonClass: 'btn--primary'
  small: true
  events:
    'click .js-copy': 'copyToClipboard'

  content: =>
    content = $(App.view('whatsapp/account_webhook')(
      channel: @channel
      callback_url: "#{@Config.get('http_type')}://#{@Config.get('fqdn')}/#{@apiPath}/channels_whatsapp_webhook/#{@channel.options?.callback_url_uuid}"
    ))

    content

  onSubmit: (e) =>
    @close()

  copyToClipboard: (e) =>
    e.preventDefault()

    button = $(e.target).parents('[role="button"]')
    field_name = button.data('targetField')
    value = $(@container).find("input[name='#{jQuery.escapeSelector(field_name)}']").val()

    @copyToClipboardWithTooltip(value, e.target,'.modal-body', true)

App.Config.set('Whatsapp', {
  prio: 5100,
  name: __('WhatsApp'),
  parent: '#channels',
  target: '#channels/whatsapp',
  controller: ChannelWhatsapp,
  permission: ['admin.channel_whatsapp']
}, 'NavBarAdmin')
