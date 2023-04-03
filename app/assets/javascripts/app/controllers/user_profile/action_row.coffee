class App.UserProfileActionRow extends App.ControllerObserverActionRow
  model: 'User'
  observe:
    verified: true
    source: true
    organization_id: true

  showHistory: (user) =>
    new App.UserHistory(
      user_id: user.id
      container: @el.closest('.content')
    )

  editUser: (user) =>
    user.secondaryOrganizations(0, 1000, =>
      new App.ControllerGenericEdit(
        id: user.id
        genericObject: 'User'
        screen: 'edit'
        pageData:
          title: __('Users')
          object: __('User')
          objects: __('Users')
        container: @el.closest('.content')
      )
    )

  newTicket: (user) =>
    @navigate("ticket/create/customer/#{user.id}")

  resendVerificationEmail: (user) =>
    @ajax(
      id:          'email_verify_send'
      type:        'POST'
      url:         @apiPath + '/users/email_verify_send'
      data:        JSON.stringify(email: user.email)
      processData: true
      success: (data, status, xhr) =>
        @notify
          type:      'success'
          msg:       App.i18n.translateContent('Email sent to "%s". Please let the user verify their email account.', user.email)
          removeAll: true
      error: (data, status, xhr) =>
        @notify
          type:      'error'
          msg:       App.i18n.translateContent('Failed to send email to "%s". Please contact an administrator.', user.email)
          removeAll: true
    )

  actions: (user) =>
    actions = [
      {
        name:     'history'
        title:    __('History')
        callback: @showHistory
      }
      {
        name:     'ticket'
        title:    __('New Ticket')
        callback: @newTicket
      }
    ]

    if user.isAccessibleBy(App.User.current(), 'change')
      actions.unshift {
        name:     'edit'
        title:    __('Edit')
        callback: @editUser
      }

      if user.verified isnt true && user.source is 'signup'
        actions.push({
          name:     'resend_verification_email'
          title:    __('Resend verification email')
          callback: @resendVerificationEmail
        })

    if @permissionCheck('admin.data_privacy')
      actions.push {
        title:    __('Delete')
        name:     'delete'
        callback: =>
          @navigate "#system/data_privacy/#{user.id}"
      }

    actions
