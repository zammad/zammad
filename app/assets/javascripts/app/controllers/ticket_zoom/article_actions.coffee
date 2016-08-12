class App.TicketZoomArticleActions extends App.Controller
  events:
    'click [data-type=public]':                    'publicInternal'
    'click [data-type=internal]':                  'publicInternal'
    'click [data-type=emailReply]':                'emailReply'
    'click [data-type=emailReplyAll]':             'emailReplyAll'
    'click [data-type=twitterStatusReply]':        'twitterStatusReply'
    'click [data-type=twitterDirectMessageReply]': 'twitterDirectMessageReply'
    'click [data-type=facebookFeedReply]':         'facebookFeedReply'

  constructor: ->
    super
    @render()

  render: ->
    actions = @actionRow(@article)

    if actions
      @html App.view('ticket_zoom/article_view_actions')(
        article: @article
        actions: actions
      )
    else
      @html ''

  publicInternal: (e) =>
    e.preventDefault()
    articleContainer = $(e.target).closest('.ticket-article-item')
    article_id = $(e.target).parents('[data-id]').data('id')

    # storage update
    article = App.TicketArticle.find(article_id)
    internal = true
    if article.internal == true
      internal = false
    @lastAttributres.internal = internal
    article.updateAttributes(internal: internal)

    # runntime update
    if internal
      articleContainer.addClass('is-internal')
    else
      articleContainer.removeClass('is-internal')

    @render()

  actionRow: (article) ->
    if @permissionCheck('ticket.customer')
      return []

    actions = []
    if article.internal is true
      actions = [
        {
          name: 'set to public'
          type: 'public'
          icon: 'lock-open'
        }
      ]
    else
      actions = [
        {
          name: 'set to internal'
          type: 'internal'
          icon: 'lock'
        }
      ]
    #if @article.type.name is 'note'
    #     actions.push []
    group = @ticket.group
    if group.email_address_id && (article.type.name is 'email' || article.type.name is 'web')
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
      recipients = []
      if article.sender.name is 'Customer'
        if article.from
          localRecipients = emailAddresses.parseAddressList(article.from)
          if localRecipients
            recipients = recipients.concat localRecipients
      if article.to
        localRecipients = emailAddresses.parseAddressList(article.to)
        if localRecipients
          recipients = recipients.concat localRecipients
      if article.cc
        localRecipients = emailAddresses.parseAddressList(article.cc)
        if localRecipients
          recipients = recipients.concat localRecipients

      # remove system addresses
      localAddresses = App.EmailAddress.all()
      forgeinRecipients = []
      recipientUsed = {}
      for recipient in recipients
        if !_.isEmpty(recipient.address)
          localRecipientAddeess = recipient.address.toString().toLowerCase()
          if !recipientUsed[localRecipientAddeess]
            recipientUsed[localRecipientAddeess] = true
            localAddess = false
            for address in localAddresses
              if localRecipientAddeess is address.email.toString().toLowerCase()
                recipientUsed[localRecipientAddeess] = true
                localAddess = true
            if !localAddess
              forgeinRecipients.push recipient

      # check if reply all is neede
      if forgeinRecipients.length > 1
        actions.push {
          name: 'reply all'
          type: 'emailReplyAll'
          icon: 'reply-all'
          href: '#'
        }
    if article.sender.name is 'Customer' && article.type.name is 'phone'
      actions.push {
        name: 'reply'
        type: 'emailReply'
        icon: 'reply'
        href: '#'
      }
    if article.type.name is 'twitter status'
      actions.push {
        name: 'reply'
        type: 'twitterStatusReply'
        icon: 'reply'
        href: '#'
      }
    if article.type.name is 'twitter direct-message'
      actions.push {
        name: 'reply'
        type: 'twitterDirectMessageReply'
        icon: 'reply'
        href: '#'
      }
    if article.type.name is 'facebook feed post' || article.type.name is 'facebook feed comment'
      actions.push {
        name: 'reply'
        type: 'facebookFeedReply'
        icon: 'reply'
        href: '#'
      }

    actions.push {
      name: 'split'
      type: 'split'
      icon: 'split'
      href: '#ticket/create/' + article.ticket_id + '/' + article.id
    }
    actions

  facebookFeedReply: (e) =>
    e.preventDefault()

    type = App.TicketArticleType.findByAttribute('name', 'facebook feed comment')
    @scrollToCompose()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )

  twitterStatusReply: (e) =>
    e.preventDefault()

    # get reference article
    article_id = $(e.target).parents('[data-id]').data('id')
    article    = App.TicketArticle.fullLocal(article_id)
    sender     = App.TicketArticleSender.find(article.sender_id)
    type       = App.TicketArticleType.find(article.type_id)
    customer   = App.User.find(article.created_by_id)

    @scrollToCompose()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    # get current body
    body = @el.closest('.ticketZoom').find('.article-add [data-name="body"]').html().trim() || ''
    articleNew.body = body

    recipients = article.from
    if article.to
      if recipients
        recipients += ' '
      recipients += article.to

    if recipients
      recipientString = ''
      recipientScreenNames = recipients.split(' ')
      for recipientScreenName in recipientScreenNames

        # exclude already listed screen name
        if !body || !body.match(recipientScreenName)

          # exclude own screen_name
          if !body || !body.match(@ticket.preferences.channel_screen_name)
            if recipientString isnt ''
              recipientString += ' '
            recipientString += recipientScreenName.trim()

    if body
      articleNew.body = "#{recipientString} #{body}&nbsp;"
    else
      articleNew.body = "#{recipientString}&nbsp;"

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )

  twitterDirectMessageReply: (e) =>
    e.preventDefault()

    # get reference article
    article_id = $(e.target).parents('[data-id]').data('id')
    article    = App.TicketArticle.fullLocal(article_id)
    type       = App.TicketArticleType.find(article.type_id)
    sender     = App.TicketArticleSender.find(article.sender_id)
    customer   = App.User.find(article.created_by_id)

    @scrollToCompose()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    if sender.name is 'Agent'
      articleNew.to = article.to
    else
      articleNew.to = article.from

    if !articleNew.to
      articleNew.to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )

  emailReplyAll: (e) =>
    @emailReply(e, true)

  emailReply: (e, all = false) =>
    e.preventDefault()

    # get reference article
    article_id = $(e.target).parents('[data-id]').data('id')
    article    = App.TicketArticle.fullLocal(article_id)
    type       = App.TicketArticleType.find(article.type_id)
    customer   = App.User.find(article.created_by_id)

    @scrollToCompose()

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    #@el.closest('[name="in_reply_to"]').val('')

    if article.message_id
      articleNew.in_reply_to = article.message_id

    if type.name is 'email' || type.name is 'phone' || type.name is 'web'

      if article.sender.name is 'Agent'
        articleNew.to = article.to
      else
        articleNew.to = article.from

        # if sender is customer but in article.from is no email, try to get
        # customers email via customer user
        if articleNew.to && !articleNew.to.match(/@/)
          articleNew.to = article.created_by.email

      # filter for uniq recipients
      recipientAddresses = {}
      recipient = emailAddresses.parseAddressList(articleNew.to)
      if recipient && recipient[0] && !_.isEmpty(recipient[0].address)
        recipientAddresses[ recipient[0].address.toString().toLowerCase() ] = true
      if all
        addAddresses = (lineNew, addressLine) ->
          localAddresses = App.EmailAddress.all()
          recipients     = emailAddresses.parseAddressList(addressLine)
          if recipients
            for recipient in recipients
              if !_.isEmpty(recipient.address)

                # check if addess is not local
                localAddess = false
                for address in localAddresses
                  if !_.isEmpty(recipient.address) && recipient.address.toString().toLowerCase() == address.email.toString().toLowerCase()
                    localAddess = true
                if !localAddess

                  # filter for uniq recipients
                  if !recipientAddresses[ recipient.address.toString().toLowerCase() ]
                    recipientAddresses[ recipient.address.toString().toLowerCase() ] = true

                    # add recipient
                    if lineNew
                      lineNew = lineNew + ', '
                    lineNew = lineNew + recipient.address
          lineNew

        if article.from
          articleNew.cc = addAddresses(articleNew.cc, article.from)
        if article.to
          articleNew.cc = addAddresses(articleNew.cc, article.to)
        if article.cc
          articleNew.cc = addAddresses(articleNew.cc, article.cc)

    # get current body
    body = @el.closest('.ticketZoom').find('.article-add [data-name="body"]').html() || ''

    # check if quote need to be added
    selectedText = App.ClipBoard.getSelected()
    if selectedText

      # clean selection
      selectedText = App.Utils.textCleanup(selectedText)

      # convert to html
      selectedText = App.Utils.text2html(selectedText)
      if selectedText
        selectedText = "<div><br><br/></div><div><blockquote type=\"cite\">#{selectedText}</blockquote></div><div><br></div>"

        # add selected text to body
        body = selectedText + body

    articleNew.body = body

    type = App.TicketArticleType.findByAttribute(name:'email')

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )

  scrollToCompose: =>
    @el.closest('.content').find('.article-add').ScrollTo()

