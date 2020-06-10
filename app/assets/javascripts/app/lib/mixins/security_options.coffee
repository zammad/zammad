# Methods for displaying security ui elements and to get security params

App.SecurityOptions =

  securityOptionsShow: ->
    @$('.js-securityOptions').removeClass('hide')

  securityOptionsHide: ->
    @$('.js-securityOptions').addClass('hide')

  securityOptionsShown: ->
    !@$('.js-securityOptions').hasClass('hide')

  securityEnabled: ->
    App.Config.get('smime_integration')

  paramsSecurity: =>
    if @$('.js-securityOptions').hasClass('hide')
      return {}

    security = {}
    security.encryption ||= {}
    security.sign ||= {}
    security.type = 'S/MIME'
    if @$('.js-securityEncrypt').hasClass('btn--active')
      security.encryption.success = true
    if @$('.js-securitySign').hasClass('btn--active')
      security.sign.success = true
    security

  updateSecurityOptionsRemote: (key, ticket, article, securityOptions) ->
    callback = =>
      @ajax(
        id:          "smime-check-#{key}"
        type:        'POST'
        url:         "#{@apiPath}/integration/smime"
        data:        JSON.stringify(ticket: ticket, article: article)
        processData: true
        success:     (data, status, xhr) =>

          # get default selected security options
          selected =
            encryption: true
            sign: true
          smimeConfig = App.Config.get('smime_config')
          for type, selector of { default_sign: 'sign', default_encryption: 'encryption' }
            if smimeConfig?.group_id?[type] && ticket.group_id
              if smimeConfig.group_id[type][ticket.group_id.toString()] == false
                selected[selector] = false

          @$('.js-securityEncryptComment').attr('title', data.encryption.comment)

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

          @$('.js-securitySignComment').attr('title', data.sign.comment)

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

        error: (data) ->
          details = data.responseJSON || {}
          console.log(details)
      )
    @delay(callback, 200, 'security-check')
