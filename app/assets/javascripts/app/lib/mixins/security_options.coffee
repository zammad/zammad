# Methods for displaying security ui elements and to get security params

App.SecurityOptions =

  securityOptionsShow: ->
    @$('.js-securityOptions').removeClass('hide')

  securityOptionsHide: ->
    @$('.js-securityOptions').addClass('hide')

  securityOptionsShown: ->
    !@$('.js-securityOptions').hasClass('hide')

  pgpSecurityEnabled: ->
    App.Config.get('pgp_integration')

  smimeSecurityEnabled: ->
    App.Config.get('smime_integration')

  securityEnabled: ->
    @pgpSecurityEnabled() or @smimeSecurityEnabled()

  securityTypeShown: ->
    @pgpSecurityEnabled() and @smimeSecurityEnabled()

  updateSecurityTypeToolbar: ->
    if @securityTypeShown()
      @$('.js-securityType[data-type="PGP"]').removeClass('btn--active')
      @$('.js-securityType[data-type="S/MIME"]').addClass('btn--active') # S/MIME is preferred type
      @$('.js-securityType').show()

    else
      @$('.js-securityType').hide()

      if @smimeSecurityEnabled()
        @$('.js-securityType[data-type="S/MIME"]').addClass('btn--active')
      else if @pgpSecurityEnabled()
        @$('.js-securityType[data-type="PGP"]').addClass('btn--active')
      else
        @$('.js-securityType').removeClass('btn--active')

  paramsSecurity: ->
    if @$('.js-securityOptions').hasClass('hide')
      return {}

    security = {}
    security.encryption ||= {}
    security.sign ||= {}
    security.type = @securityType()
    if @$('.js-securityEncrypt').hasClass('btn--active')
      security.encryption.success = true
    if @$('.js-securitySign').hasClass('btn--active')
      security.sign.success = true
    security

  securityType: ->
    @$('.js-securityType.btn--active').data('type')

  securityTypeName: ->
    type = @securityType()
    return if not type

    if type is 'S/MIME'
      return 'smime'
    else if type is 'PGP'
      return 'pgp'

  updateSecurityOptionsRemote: (key, ticket, article) ->
    return if not @securityEnabled()

    type = @securityTypeName()
    return if not type

    callback = =>
      @ajax(
        id:          "#{type}-check-#{key}"
        type:        'POST'
        url:         "#{@apiPath}/integration/#{type}"
        data:        JSON.stringify(ticket: ticket, article: article)
        processData: true
        success:     (data, status, xhr) =>

          # get default selected security options
          selected =
            encryption: true
            sign: true
          securityConfig = App.Config.get("#{type}_config")
          for type, selector of { default_sign: 'sign', default_encryption: 'encryption' }
            if securityConfig?.group_id?[type] && ticket.group_id
              if securityConfig.group_id[type][ticket.group_id.toString()] == false
                selected[selector] = false

          @$('.js-securityEncryptComment').attr('title', App.i18n.translateContent(data.encryption.comment || '', data.encryption.commentPlaceholders))

          # if encryption is possible
          if data.encryption.success is true
            @$('.js-securityEncrypt').attr('disabled', false)

            # overrule current selection with Group configuration
            if selected.encryption
              @$('.js-securityEncrypt').addClass('btn--active')
            else
              @$('.js-securityEncrypt').removeClass('btn--active')

          # if encryption is not possible
          else
            @$('.js-securityEncrypt').attr('disabled', true)
            @$('.js-securityEncrypt').removeClass('btn--active')

          @$('.js-securitySignComment').attr('title', App.i18n.translateContent(data.sign.comment || '', data.sign.commentPlaceholders))

          # if sign is possible
          if data.sign.success is true
            @$('.js-securitySign').attr('disabled', false)

            # overrule current selection with Group configuration
            if selected.sign
              @$('.js-securitySign').addClass('btn--active')
            else
              @$('.js-securitySign').removeClass('btn--active')

          # if sign is possible
          else
            @$('.js-securitySign').attr('disabled', true)
            @$('.js-securitySign').removeClass('btn--active')
      )
    @delay(callback, 200, 'security-check')

  securityOptionsReset: ->
    @$('.js-securityEncryptComment').removeAttr('title')
    @$('.js-securityEncrypt').attr('disabled', true).removeClass('btn--active')
    @$('.js-securitySignComment').removeAttr('title')
    @$('.js-securitySign').attr('disabled', true).removeClass('btn--active')
