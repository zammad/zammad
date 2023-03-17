class CheckMk extends App.ControllerIntegrationBase
  featureIntegration: 'check_mk_integration'
  featureName: __('Checkmk')
  featureConfig: 'check_mk_config'
  description: [
    [__('This service receives HTTP requests or emails from %s and creates tickets with host and service.'), 'Checkmk']
    [__('If the host and service have recovered, the ticket can be closed automatically.')]
  ]

  render: =>
    super

    new App.SettingsForm(
      area: 'Integration::CheckMK'
      el: @$('.js-form')
    )

    new Form(
      el: @$('.js-usage')
    )

    new App.HttpLog(
      el: @$('.js-log')
      facility: 'check_mk'
    )

class State
  @current: ->
    App.Setting.get('check_mk_integration')

class Form extends App.Controller
  events:
    'click .js-tabItem': 'toogle'
    'click .js-select': 'selectAll'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('integration/check_mk')()

    @$('.js-code').each((i, block) ->
      hljs.highlightBlock block
    )

  toogle: (e) =>
    target = $(e.target).data('tablist')
    @$('.js-tablistItem').addClass('hidden')
    @$(".js-#{target}").removeClass('hidden')

App.Config.set(
  'IntegrationCheckMk'
  {
    name: __('Checkmk')
    target: '#system/integration/check_mk'
    description: __('An open-source monitoring tool.')
    controller: CheckMk
    state: State
    permission: ['admin.integration.check_mk']
  }
  'NavBarIntegrations'
)
