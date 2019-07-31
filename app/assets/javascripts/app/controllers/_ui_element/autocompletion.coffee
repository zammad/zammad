# coffeelint: disable=camel_case_classes,no_interpolation_in_single_quotes
class App.UiElement.autocompletion
  @render: (attribute, params) ->

    if params[ attribute.name + '_autocompletion_value_shown' ]
      attribute.valueShown = params[ attribute.name + '_autocompletion_value_shown' ]

    item = $( App.view('generic/autocompletion')( attribute: attribute ) )

    a = =>
      local_attribute      = '#' + attribute.id
      local_attribute_full = '#' + attribute.id + '_autocompletion'
      @callback            = attribute.callback

      # call calback on init
      if @callback && attribute.value && @params
        @callback(@params)

      b = (event, item) =>
        # set html form attribute
        $(local_attribute).val(item.id).trigger('change')
        $(local_attribute + '_autocompletion_value_shown').val(item.value)

        # call callback
        if @callback
          params = App.ControllerForm.params(form)
          @callback(params)
      ###
      $(@local_attribute_full).tagsInput(
        autocomplete_url: '/users/search',
        height: '30px',
        width: '530px',
        auto: {
          source: '/users/search',
          minLength: 2,
          select: (event, ui) ->
            #@log 'notice', 'selected', event, ui
            b(event, ui.item)
        }
      )
      ###
      source = attribute.source
      if typeof(source) is 'string'
        source = source.replace('#{@apiPath}', App.Config.get('api_path') )
      $(local_attribute_full).autocomplete(
        source: source,
        minLength: attribute.minLengt || 3,
        select: (event, ui) ->
          b(event, ui.item)
      )
    App.Delay.set(a, 280, undefined, 'form_autocompletion')
    item
