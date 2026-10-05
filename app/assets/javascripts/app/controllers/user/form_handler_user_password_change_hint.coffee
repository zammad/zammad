# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class App.FormHandlerUserPasswordChangeHint
  @run: (params, attribute, attributes, classname, form, ui) ->
    # The form renames the password attribute to password_confirm, so it cannot be matched by name.
    return if ui.FormHandlerUserPasswordChangeHintDone
    return if !$(form).find('input[name=password]').length
    ui.FormHandlerUserPasswordChangeHintDone = true

    # Users changing their own password are not notified by this path.
    return if ui.params?.id is App.Session.get('id')

    $(form).off('input.password_change_hint').on('input.password_change_hint', 'input[name=password], input[name=email]', ->
      password = $(form).find('input[name=password]').val()
      email    = $(form).find('input[name=email]').val()

      hint = ''
      if !_.isEmpty(password) && (!_.isEmpty(email) || !_.isEmpty(ui.params?.email))
        hint = App.i18n.translateContent('The user will be notified of the password change by email.')

      $(form).find('input[name=password]')
        .closest('.form-group')
        .find('.help-block')
        .html(hint)
    )
