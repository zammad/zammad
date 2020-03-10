class App.ColumnSelect extends Spine.Controller
  elements:
    '.js-pool': 'pool'
    '.js-selected': 'selected'
    '.js-shadow': 'shadow'
    '.js-placeholder': 'placeholder'
    '.js-pool .js-option': 'poolOptions'
    '.js-selected .js-option': 'selectedOptions'
    '.js-search': 'search'
    '.js-clear': 'clearButton'

  events:
    'click .js-select': 'onSelect'
    'click .js-remove': 'onRemove'
    'input .js-search': 'filter'
    'click .js-clear': 'clear'
    'keydown .js-search': 'onFilterKeydown'

  className: 'form-control columnSelect'

  element: =>
    @el

  constructor: ->
    super
    @render()

    @throttledRemove = _.throttle =>
      @remove @pickedValue
    , 300, {trailing: false}

    @throttledSelect = _.throttle =>
      @select @pickedValue
    , 300, {trailing: false}

    if @attribute.onChange
      @shadow.on('change', =>
        @attribute.onChange(@shadow.val())
      )

  render: ->
    if !_.isEmpty(@attribute.seperator)
      values = []
      if @attribute.value
        values = @attribute.value.split(@attribute.seperator)
      else if @attribute.default
        values = @attribute.default.split(@attribute.seperator)

      for value in values
        for option in @options.attribute.options
          # is grouped
          if option.group is not undefined
            for o in option.group
              if o.value is value
                o.selected = true
          else if option.value is value
            option.selected = true

    @values = []
    allOptions = []
    _.each @options.attribute.options, (option) =>
      # is grouped
      if option.group != undefined
        for o in option.group
          allOptions.push(o)
          if o.selected
            @values.push o.value.toString()
      else
        allOptions.push(option)
        if option.selected
          @values.push option.value.toString()

    @html App.view('generic/column_select')(
      attribute: @options.attribute
      allOptions: allOptions
      values: @values
    )

    # keep inital height
    # disabled for now since controls in modals get rendered hidden
    # and thus have no height
    # setTimeout =>
    #   @el.css 'height', @el.height()
    # , 0

  onSelect: (event) ->
    @pickedValue = $(event.currentTarget).attr('data-value')
    @throttledSelect()

  select: (value) ->
    @selected.find("[data-value='#{value}']").removeClass('is-hidden')
    @pool.find("[data-value='#{value}']").addClass('is-hidden')
    @values.push(value)

    if !_.isEmpty(@attribute.seperator)
      @shadow.val(@values.join(';'))
    else
      @shadow.val(@values)
      @shadow.trigger('change')

    @placeholder.addClass('is-hidden')

    if @search.val() and @poolOptions.not('.is-filtered').not('.is-hidden').size() is 0
      @clear()

  onRemove: (event) ->
    @pickedValue = $(event.currentTarget).attr('data-value')
    @throttledRemove()

  remove: (value) ->
    @pool.find("[data-value='#{value}']").removeClass('is-hidden')
    @selected.find("[data-value='#{value}']").addClass('is-hidden')
    @values.splice(@values.indexOf(value), 1)
    if !_.isEmpty(@attribute.seperator)
      @shadow.val(@values.join(';'))
    else
      @shadow.val(@values)
      @shadow.trigger('change')

    if !@values.length
      @placeholder.removeClass('is-hidden')

  filter: (event) ->
    filter = $(event.currentTarget).val()

    @poolOptions.each (i, el) ->
      return if $(el).hasClass('is-hidden')

      if $(el).text().toLowerCase().indexOf(filter.toLowerCase()) > -1
        $(el).removeClass('is-filtered')
      else
        $(el).addClass('is-filtered')

    @clearButton.toggleClass 'is-hidden', filter.length is 0
    @pool.toggleClass 'filter-active', filter.length != 0

  clear: ->
    @search.val('')
    @poolOptions.removeClass('is-filtered')
    @clearButton.addClass('is-hidden')

  onFilterKeydown: (event) ->
    return if event.keyCode != 13

    event.stopPropagation()
    event.preventDefault()

    firstVisibleOption = @poolOptions.not('.is-filtered').not('.is-hidden').first()
    if firstVisibleOption
      @select firstVisibleOption.attr('data-value')
