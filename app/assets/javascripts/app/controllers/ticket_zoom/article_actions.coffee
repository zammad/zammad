class App.TicketZoomArticleActions extends App.Controller
  events:
    'click [data-type=public]':   'publicInternal'
    'click [data-type=internal]': 'publicInternal'
    'click [data-type=reply]':    'reply'
    'click [data-type=replyAll]': 'replyAll'

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

  publicInternal: (e) ->
    e.preventDefault()
    articleContainer = $(e.target).closest('.ticket-article-item')
    article_id = $(e.target).parents('[data-id]').data('id')

    # storage update
    article = App.TicketArticle.find(article_id)
    internal = true
    if article.internal == true
      internal = false
    article.updateAttributes(
      internal: internal
    )

    # runntime update
    if internal
      articleContainer.addClass('is-internal')
    else
      articleContainer.removeClass('is-internal')

    @render()

  actionRow: (article) ->
    if @isRole('Customer')
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
    if article.type.name is 'email' || article.type.name is 'phone' || article.type.name is 'web'
      actions.push {
        name: 'reply'
        type: 'reply'
        icon: 'reply'
        href: '#'
      }
      recipients = []
      if article.sender.name is 'Agent'
        if article.to
          localRecipients = emailAddresses.parseAddressList(article.to)
          if localRecipients
            recipients = recipients.concat localRecipients
      else
        if article.from
          localRecipients = emailAddresses.parseAddressList(article.from)
          if localRecipients
            recipients = recipients.concat localRecipients
      if article.cc
        localRecipients = emailAddresses.parseAddressList(article.cc)
        if localRecipients
          recipients = recipients.concat localRecipients
      if recipients.length > 1
        actions.push {
          name: 'reply all'
          type: 'replyAll'
          icon: 'reply-all'
          href: '#'
        }
    actions.push {
      name: 'split'
      type: 'split'
      icon: 'split'
      href: '#ticket/create/' + article.ticket_id + '/' + article.id
    }
    actions

  replyAll: (e) =>
    @reply(e, true)

  reply: (e, all = false) =>
    e.preventDefault()

    # get reference article
    article_id = $(e.target).parents('[data-id]').data('id')
    article    = App.TicketArticle.fullLocal( article_id )
    type       = App.TicketArticleType.find( article.type_id )
    customer   = App.User.find( article.created_by_id )

    @el.closest('.article-add').ScrollTo()

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

    if type.name is 'twitter status'

      # set to in body
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      articleNew.body = '@' + to

    else if type.name is 'twitter direct-message'

      # show to
      to = customer.accounts['twitter'].username || customer.accounts['twitter'].uid
      articleNew.to = to

    else if type.name is 'email' || type.name is 'phone' || type.name is 'web'

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
      if recipient && recipient[0]
        recipientAddresses[ recipient[0].address.toString().toLowerCase() ] = true
      if all
        addAddresses = (lineNew, addressLine) ->
          localAddresses = App.EmailAddress.all()
          recipients     = emailAddresses.parseAddressList(addressLine)
          if recipients
            for recipient in recipients
              if recipient.address

                # check if addess is not local
                localAddess = false
                for address in localAddresses
                  if recipient.address.toString().toLowerCase() == address.email.toString().toLowerCase()
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
      selectedText = App.Utils.textCleanup( selectedText )

      # convert to html
      selectedText = App.Utils.text2html( selectedText )
      if selectedText
        selectedText = "<div><br><br/></div><div><blockquote type=\"cite\">#{selectedText}</blockquote></div><div><br></div>"

        # add selected text to body
        body = selectedText + body

    articleNew.body = body

    App.Event.trigger('ui::ticket::setArticleType', { ticket: @ticket, type: type, article: articleNew } )
