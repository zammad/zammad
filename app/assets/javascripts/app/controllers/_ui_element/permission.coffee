# coffeelint: disable=camel_case_classes
class App.UiElement.permission extends App.UiElement.ApplicationUiElement
  @render: (attribute, params = {}) ->
    permissions = App.Permission.search(sortBy: 'name')

    item = $( App.view('generic/permission')(
      attribute:   attribute
      params:      params
      permissions: permissions
    ) )

    # show/hide trees
    item.find('[name=permission_ids]')
      .on('change', (e) =>
        @checkUncheck($(e.currentTarget), permissions, item)
      )
      .trigger('change')

    item

  @checkUncheck: (element, permissions, item) ->
    checked    = element.prop('checked')
    permission = App.Permission.find(element.prop('value'))
    return if !permission

    if !permission.name.match(/\./)
      # show/hide sub permissions
      for localPermission in permissions
        regexp = new RegExp("^#{permission.name}")
        if localPermission.name.match(regexp)
          item
            .find("[name=permission_ids][value=#{localPermission.id}]")
            .closest('.js-subPermissionList')
            .toggleClass('hide', checked)

    if checked && permission.preferences.not
      for localPermission in permission.preferences.not
        lookupPermission = App.Permission.findByAttribute('name', localPermission)

        if lookupPermission
          item.find("[name=permission_ids][value=#{lookupPermission.id}]").prop('checked', false)
