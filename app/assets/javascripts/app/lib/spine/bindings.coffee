BindingsClass =

  model: 'model'

  bindings: {}


class ValueSetter

  constructor: (@context) ->

  setValue: (element, value, setter) ->
    if typeof setter is 'string'
      setter = @context.proxy(@context[setter])
    setter = setter || (e, v) => @_standardSetter e, v
    setter element, value

  getValue: (element, getter) ->
    if typeof getter is 'string'
      getter = @context.proxy(@context[getter])
    getter = getter || (e, v) => @_standardGetter e, v
    getter element

  _standardGetter: (element) ->
    self = this
    self["_#{element.attr('type')}Get"]?(element) || element.val()

  _standardSetter: (element, value) ->
    self = this
    element.each ->
      el = $(this)
      self["_#{el.attr('type')}Set"]?(el, value) || el.val(value)

  _checkboxSet: (element, value) ->
    if value
      element.prop('checked', 'checked')
    else
      element.prop('checked', '')

  _checkboxGet: (element) ->
    element.is(':checked')

BindingsInstance =

  getModel: ->
    @[@modelVar]

  setModel: (model) ->
    @[@modelVar] = model

  walkBindings: (fn) ->
    for selector, field of @bindings
      fn selector, field

  applyBindings: ->
    @valueSetter = new ValueSetter @
    @walkBindings (selector, field) =>
      if not field.direction or field.direction is 'model'
        @_bindModelToEl @getModel(), field, selector
      if not field.direction or field.direction is 'element'
        @_bindElToModel @getModel(), field, selector

  _getField: (value) ->
    if typeof value is 'string'
      value
    else
      value.field

  _forceModelBindings: (model) ->
    @walkBindings (selector, field) =>
      @valueSetter.setValue @$(selector), model[@_getField(field)], field.setter

  changeBindingSource: (model) ->
    @getModel().unbind 'change'
    @walkBindings (selector) =>
      selector = false if selector is 'self'
      @el.off 'change', selector
    @setModel model
    @_forceModelBindings model
    do @applyBindings

  _bindModelToEl: (model, field, selector) ->
    self = @
    selector = false if selector is 'self'
    @el.on 'change', selector, ->
      model[self._getField(field)] = self.valueSetter.getValue $(this), field.getter

  _bindElToModel: (model, field, selector) ->
    model.bind 'change', =>
      @valueSetter.setValue @$(selector), model[@_getField(field)], field.setter

Spine.Bindings =
  extended: ->
    @extend BindingsClass
    @include BindingsInstance
