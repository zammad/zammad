# Handler for localization of execution changes in scheduler and trigger modals.
#   Collapses/expands localization and timezone fields depending on the state of the switch.
#
# Additional code is needed to call the function to manipulate attribute array:
#
#  contentFormModel: =>
#    params = @contentFormParams() or {}
#    attrs = _.clone(App[ @genericObject ].configure_attributes)
#
#    attrs = @prepareExecutionLocalizationAttributes(params, attrs)
#
#    { configure_attributes: attrs }
#
# Make sure to also register the change event handler in your target class, like so:
#
#  events:
#    'change input[name="execution_localization"]': 'executionLocalizationChanged'

App.ExecutionLocalizationMixin =
  prepareExecutionLocalizationAttributes: (params, attrs) ->
    # Expand locale and timezone fields in case they are not set to system defaults.
    if (params.localization and params.localization isnt 'system') or (params.timezone and params.timezone isnt 'system')
      _.findWhere(attrs, { name: 'execution_localization'}).value = true
      _.findWhere(attrs, { name: 'localization'}).item_class += ' in'
      _.findWhere(attrs, { name: 'timezone'}).item_class += ' in'
    else
      _.findWhere(attrs, { name: 'execution_localization'}).value = false
      localization = _.findWhere(attrs, { name: 'localization'})
      localization.item_class = localization.item_class.replace /\sin$/, ''
      timezone = _.findWhere(attrs, { name: 'timezone'})
      timezone.item_class = timezone.item_class.replace /\sin$/, ''

    attrs

  executionLocalizationChanged: (e) ->
    e.preventDefault()

    localizationCollapseWidget = @el.find('[data-attribute-name="localization"]')
    timezoneCollapseWidget = @el.find('[data-attribute-name="timezone"]')

    # Show or hide the locale and timezone fields depending on the switch value.
    if $(e.target).is(':checked')
      localizationCollapseWidget.collapse('show')
      timezoneCollapseWidget.collapse('show')
      @el.find('[data-attribute-name="localization"]').css('margin-bottom', '')
      @el.find('[data-attribute-name="timezone"]').css('margin-bottom', '')
    else
      localizationCollapseWidget.collapse('hide')
      timezoneCollapseWidget.collapse('hide')
      @el.find('[data-attribute-name="localization"]').css('margin-bottom', '0')
      @el.find('[data-attribute-name="timezone"]').css('margin-bottom', '0')
