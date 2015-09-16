class App.UiElement.ical_feed extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->
    console.log('A', attribute)
    item = $( '<div>' + App.view('generic/input')( attribute: attribute ) + '</div>' )

    ical_feeds = App.Config.get('ical_feeds')

    if !_.isEmpty(ical_feeds)
      attribute_ical =
        options:    ical_feeds
        tag:        'searchable_select'
        placeholder: App.i18n.translateInline('Search public ical feed...')

      # build options list based on config
      @getConfigOptionList( attribute_ical )

      # add null selection if needed
      @addNullOption( attribute_ical )

      # sort attribute.options
      @sortOptions( attribute_ical )

      # finde selected/checked item of list
      @selectedOptions( attribute_ical )

      templateSelections =  App.UiElement.searchable_select.render(attribute_ical)

      templateSelections.find('.js-shadow').bind('change', (e) ->
        val = $(e.target).val()
        if val
          item.find("[name=#{attribute.name}]").val(val)
      )
      item.append(templateSelections)

    item