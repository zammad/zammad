# coffeelint: disable=no_unnecessary_double_quotes
class ChannelForm extends App.ControllerSubContent
  @requiredPermission: 'admin.channel_formular'
  header: __('Form')
  events:
    'change form.js-paramsDesigner': 'updateParamsDesigner'
    'keyup form.js-paramsDesigner': 'updateParamsDesigner'
    'change .js-formSetting input': 'toggleFormSetting'
    'change .js-paramsSetting .js-shadow': 'updateGroup'
    'change .js-spamProtection [name=form_ticket_create_honeypot]': 'toggleHoneypot'
    'change .js-spamProtection [name=form_ticket_create_captcha_provider]': 'updateCaptchaProvider'
    'change .js-spamProtection [name=sitekey]': 'updateCaptchaOptions'
    'change .js-spamProtection [name=secret]': 'updateCaptchaOptions'
    'change .js-spamProtection [name=project_id]': 'updateCaptchaOptions'
    'change .js-spamProtection [name=api_key]': 'updateCaptchaOptions'
    'change .js-spamProtection [name=min_score]': 'updateCaptchaOptions'

  # coffeelint: disable=detect_translatable_string
  # Provider names are brand names; rendered through @T so translators can still adapt them.
  captchaProviders: [
    { value: '',                 label: '-' }
    { value: 'altcha',           label: 'ALTCHA' }
    { value: 'turnstile',        label: 'Cloudflare Turnstile' }
    { value: 'hcaptcha',         label: 'hCaptcha' }
    { value: 'friendly_captcha', label: 'Friendly Captcha' }
    { value: 'recaptcha',        label: 'Google reCAPTCHA' }
    { value: 'recaptcha_enterprise', label: 'Google reCAPTCHA Enterprise' }
  ]
  # coffeelint: enable=detect_translatable_string

  elements:
    '.js-code': 'code'
    '.js-paramsSetting': 'paramsSetting'
    '.js-formSetting input': 'formSetting'

  constructor: ->
    super

    @title __('Form'), true
    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>
    setting = App.Setting.get('form_ticket_create')

    captchaProvider = App.Setting.get('form_ticket_create_captcha_provider') or ''
    captchaOptions  = App.Setting.get('form_ticket_create_captcha_options') or {}

    element = $(App.view('channel/form')(
      baseurl:          window.location.origin
      formSetting:      setting
      honeypot:         App.Setting.get('form_ticket_create_honeypot')
      captchaProviders:    @captchaProviders
      captchaProvider:     captchaProvider
      captchaNeedsSiteKey: @captchaNeedsSiteKey(captchaProvider)
      captchaNeedsSecret:  @captchaNeedsSecret(captchaProvider)
      captchaIsEnterprise: @captchaIsEnterprise(captchaProvider)
      captchaNeedsScore:   @captchaNeedsScore(captchaProvider)
      captchaSiteKey:      captchaOptions.sitekey or ''
      captchaSecret:       captchaOptions.secret or ''
      captchaProjectId:    captchaOptions.project_id or ''
      captchaApiKey:       captchaOptions.api_key or ''
      captchaMinScore:     captchaOptions.min_score or ''
    ))

    group_id = App.Setting.get('form_ticket_create_group_id')
    selection = App.UiElement.tree_select.render(
      name: 'group_id'
      multiple: false
      null: false
      relation: 'Group'
      nulloption: false
      value: group_id
      #class: 'form-control--small'
    )
    agreementTextInput = App.UiElement.richtext.render(
      name: "agreementMessage"
      buttons: [ 'link']
      null: false
      noImages: true
      id: 'form-message-agreement'
      tag:     'richtext'
      value: __('Accept Data Privacy Policy & Acceptable Use Policy')
    )
    element.find('.js-groupSelector').html(selection)
    element.find('.agreement-support-text').html(agreementTextInput)

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

    if @$('#agreementSupport').prop('checked')
      @$('.agreement-support-text').removeClass('hide')
    else
      @$('.agreement-support-text').addClass('hide')
      delete params.agreementMessage

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
      @$('.js-formInline').toggleClass('no-css', !!params.noCSS)
    else
      @$('.js-modal').addClass('hide')
      @$('.js-inlineForm').removeClass('hide')
      @$('.js-formBtn').addClass('hide')
      @$('.js-formInline').removeClass('hide')
      @$('.js-formInline').ZammadForm(params)
      @$('.js-formInline').toggleClass('no-css', !!params.noCSS)

  toggleFormSetting: =>
    value = @formSetting.prop('checked')
    App.Setting.set('form_ticket_create', value, doneLocal: @notifySaved)

  updateGroup: =>
    value = @paramsSetting.find('[name=group_id]').val()
    App.Setting.set('form_ticket_create_group_id', value, doneLocal: @notifySaved)

  captchaNeedsSiteKey: (provider) ->
    provider isnt '' and provider isnt 'altcha'

  captchaNeedsSecret: (provider) ->
    provider in ['turnstile', 'hcaptcha', 'friendly_captcha', 'recaptcha']

  captchaIsEnterprise: (provider) ->
    provider is 'recaptcha_enterprise'

  captchaNeedsScore: (provider) ->
    provider in ['recaptcha', 'recaptcha_enterprise']

  notifySaved: =>
    @notify
      type: 'success'
      msg: __('Update successful.')

  toggleHoneypot: (e) ->
    App.Setting.set('form_ticket_create_honeypot', $(e.currentTarget).prop('checked'), doneLocal: @notifySaved)

  updateCaptchaProvider: (e) =>
    provider = $(e.currentTarget).val()
    App.Setting.set('form_ticket_create_captcha_provider', provider, doneLocal: @notifySaved)

    # clear the previous provider's credentials so they are neither shown nor kept
    for name in ['sitekey', 'secret', 'project_id', 'api_key', 'min_score']
      @$(".js-spamProtection [name=#{name}]").val('')
    App.Setting.set('form_ticket_create_captcha_options', {})

    @$('.js-captchaSiteKey').toggleClass('hide', !@captchaNeedsSiteKey(provider))
    @$('.js-captchaSecret').toggleClass('hide', !@captchaNeedsSecret(provider))
    @$('.js-captchaEnterprise').toggleClass('hide', !@captchaIsEnterprise(provider))
    @$('.js-captchaScore').toggleClass('hide', !@captchaNeedsScore(provider))

  updateCaptchaOptions: =>
    options = {}
    for field in ['sitekey', 'secret', 'project_id', 'api_key']
      value = @$(".js-spamProtection [name=#{field}]:visible").val()
      options[field] = value if value

    # only persist a valid score threshold (0–1); otherwise the server falls back to its default
    minScore = parseFloat(@$('.js-spamProtection [name=min_score]:visible').val())
    options.min_score = minScore if not isNaN(minScore) and minScore >= 0 and minScore <= 1

    App.Setting.set('form_ticket_create_captcha_options', options, doneLocal: @notifySaved)

App.Config.set('Form', { prio: 2000, name: __('Form'), parent: '#channels', target: '#channels/form', controller: ChannelForm, permission: ['admin.channel_formular'] }, 'NavBarAdmin')
