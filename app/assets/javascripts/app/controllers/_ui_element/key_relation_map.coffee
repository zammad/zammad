# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Maps free text keys to records of a relation, e.g. identity provider values to roles:
#   { 'zammad-agent': [2], 'zammad-admin': [1, 2] }
# coffeelint: disable=camel_case_classes
class App.UiElement.key_relation_map extends Spine.Module
  @render: (attribute, params = {}) ->
    value = if _.isObject(attribute.value) and not _.isArray(attribute.value) then attribute.value else {}

    item = $(App.view('generic/key_relation_map')(
      attribute:       attribute
      valueRaw:        JSON.stringify(value)
      keyDisplay:      attribute.key_display or __('Value')
      relationDisplay: attribute.relation_display or attribute.relation
    ))

    for key, relationIds of value
      @addRow(item, attribute, key, relationIds)

    item.on('click', '.js-addRow', (e) =>
      e.preventDefault()
      @addRow(item, attribute).find('.js-key').trigger('focus')
      @sync(item)
    )
    item.on('click', '.js-removeRow', (e) =>
      e.preventDefault()
      $(e.currentTarget).closest('.js-row').remove()
      @sync(item)
    )
    item.on('input change', '.js-row', => @sync(item))

    @toggleEmpty(item)

    item

  @addRow: (item, attribute, key = '', relationIds = []) ->
    row = $(App.view('generic/key_relation_map_row')(
      key:             key
      keyDisplay:      attribute.key_display or __('Value')
      keyPlaceholder:  attribute.key_placeholder or ''
      relationDisplay: attribute.relation_display or attribute.relation
    ))

    relationAttribute =
      name:      "#{attribute.name}_relation"
      multiple:  'multiple'
      relation:  attribute.relation
      translate: true
      null:      true
      class:     'form-control--small'
      value:     _.map(relationIds, (id) -> id.toString())

    # Options marked as selected make App.SearchableSelect keep only the first of several values,
    #   so the options are built without App.UiElement.searchable_select.selectedOptions.
    App.UiElement.searchable_select.getRelationOptionList(relationAttribute, {})
    App.UiElement.searchable_select.sortOptions(relationAttribute, {})
    relation = new App.SearchableSelect(attribute: relationAttribute).element()

    # The hidden input holds the value, the inputs of a row must not end up in the form params.
    relation.find('[name]').removeAttr('name')
    relation.find('.js-input').attr('aria-label', App.i18n.translatePlain(attribute.relation_display or attribute.relation))

    row.find('.js-relation').html(relation)
    item.find('.js-rows').append(row)
    @toggleEmpty(item)

    row

  @sync: (item) ->
    # Without a prototype, keys like __proto__ or hasOwnProperty are plain entries.
    value = Object.create(null)

    item.find('.js-row').each( ->
      key         = $(@).find('.js-key').val().trim()
      relationIds = _.map(_.compact(_.flatten([$(@).find('.js-shadow').val()])), (id) -> parseInt(id, 10))

      return if key is '' and relationIds.length is 0

      value[key] = _.union(value[key] or [], relationIds)
    )

    item.find('.js-keyRelationMapValue').val(JSON.stringify(value))
    @toggleEmpty(item)

  @toggleEmpty: (item) ->
    item.find('.js-empty').toggleClass('hide', item.find('.js-row').length > 0)
