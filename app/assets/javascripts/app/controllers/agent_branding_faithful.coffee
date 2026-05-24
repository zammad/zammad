# Faithful agent Branding panel — matches docs/ui-references/agent-console/
# (BrandingPanel in agent-manage.jsx).
#
# Bound to the Settings tab row (Branding / System / Security / API) so the
# user can switch between the faithful settings panels and the legacy
# App.Manage rendering for the others.
class App.AgentBrandingFaithful extends App.Controller
  @requiredPermission: 'admin.branding'

  events:
    'click .js-section':       'onSectionClick'
    'click .js-save':          'onSave'
    'click .js-color':         'onColorPick'
    'click .js-logo-upload':   'onLogoUpload'
    'click .js-logo-reset':    'onLogoReset'
    'change input[type=file]': 'onFileSelected'

  constructor: (params) ->
    super
    @title __('Branding'), true
    @navupdate '#settings/branding'

    @productName     = App.Config.get('product_name')  or 'Zammad Helpdesk'
    @organization    = App.Config.get('organization')  or ''
    @logoUrl         = "/assets/images/#{App.Config.get('product_logo') or 'logo.svg'}"
    @activeColor     = 'indigo'

    @render()

  release: => super

  onSectionClick: (e) =>
    e.preventDefault()
    target = $(e.currentTarget).data('section')
    return if !target
    @navigate target

  onSave: (e) =>
    e.preventDefault()
    key = $(e.currentTarget).data('key')
    val = @$(".js-input[data-key='#{key}']").val()
    return if !key
    App.Setting.set(key, val)
    if key is 'product_name' then @productName = val else @organization = val
    @notify(
      type: 'success'
      msg: App.i18n.translateContent('%s saved', key)
      timeout: 2000
    )

  onColorPick: (e) =>
    e.preventDefault()
    color = $(e.currentTarget).data('color')
    return if !color
    @activeColor = color
    @$('.js-color').removeClass('ac-color-chip--on')
    $(e.currentTarget).addClass('ac-color-chip--on')

  onLogoUpload: (e) =>
    e.preventDefault()
    @$('input[type=file]').trigger('click')

  onFileSelected: (e) =>
    file = e.target.files?[0]
    return if !file
    reader = new FileReader()
    reader.onload = (ev) =>
      data = ev.target.result
      @ajax(
        id:    'agent_branding_logo'
        type:  'POST'
        url:   "#{@apiPath}/users/image"
        data:  JSON.stringify(data: data, filename: file.name)
        processData: false
        success: (resp) =>
          @notify(type: 'success', msg: 'Logo updated', timeout: 2000)
      )
    reader.readAsDataURL(file)

  onLogoReset: (e) =>
    e.preventDefault()
    App.Setting.set('product_logo', 'logo.svg')
    @logoUrl = '/assets/images/logo.svg'
    @render()

  sections: ->
    items = [
      { key: 'branding', label: 'Branding', href: '#settings/branding' }
      { key: 'system',   label: 'System',   href: '#settings/system' }
      { key: 'security', label: 'Security', href: '#settings/security' }
      { key: 'api',      label: 'API',      href: '#settings/api' }
    ]
    item.active = (item.key is 'branding') for item in items
    items

  colors: ->
    [
      { key: 'indigo', label: 'Indigo', hex: '#4F46E5' }
      { key: 'teal',   label: 'Teal',   hex: '#0D9488' }
      { key: 'rose',   label: 'Rose',   hex: '#E11D48' }
      { key: 'slate',  label: 'Slate',  hex: '#475569' }
    ]

  render: =>
    @html App.view('agent_branding_faithful')(
      sections:     @sections()
      productName:  @productName
      organization: @organization
      logoUrl:      @logoUrl
      colors:       @colors()
      activeColor:  @activeColor
    )

App.Config.set('AgentBrandingFaithful', { controller: 'AgentBrandingFaithful', permission: ['admin.branding'] }, 'permanentTask')
