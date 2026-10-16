class App.FullQuoteHeader
  @fullQuoteHeaderForward: (article) ->
    if !App.Config.get('ui_ticket_zoom_article_email_full_quote_header')
      return ''

    output = document.createElement('div')

    data = {
      Subject: article.subject
      Date:    App.i18n.translateTimestamp(article.created_at)
      From:    @fullQuoteHeaderForwardFrom(article)
      To:      @fullQuoteHeaderForwardTo(article)
      CC:      @fullQuoteHeaderForwardCC(article)
    }

    for key, value of data
      if value
        output.append App.i18n.translateContent(key), ': ', value, document.createElement('br')

    output.append document.createElement('br')

    output.outerHTML

  @fullQuoteHeaderForwardFrom: (article) ->
    user_id = article.origin_by_id || article.created_by_id

    @fullQuoteHeaderEnsurePrivacy(user_id, article, true) || @fullQuoteHeaderEnsurePrivacy(article.from, article, true) || article.from

  @fullQuoteHeaderForwardTo: (article) ->
    if article.type.name is 'email' || article.type.name is 'web'
      @fullQuoteHeaderEnsureMultiPrivacy(article.to, article)
    else if article.sender.name is 'Customer' && article.type.name is 'phone'
      # Inbound phone articles record the group name as recipient.
      email_address_id = App.Group.findByAttribute('name', article.to)?.email_address_id
      email_address    = App.EmailAddress.find(email_address_id)
      return article.to if !email_address

      App.Utils.buildEmailAddress(email_address.name, email_address.email)
    else if article.sender.name is 'Agent' && article.type.name is 'phone'
      ticket = App.Ticket.find(article.ticket_id)
      @fullQuoteHeaderEnsurePrivacy(ticket.customer_id, article) || @fullQuoteHeaderEnsureMultiPrivacy(article.to, article)
    else
      article.to

  @fullQuoteHeaderForwardCC: (article) ->
    @fullQuoteHeaderEnsureMultiPrivacy(article.cc, article)

  @fullQuoteHeaderEnsureMultiPrivacy: (input, article) ->
    return if !input

    @fullQuoteHeaderParseRecipients(input)
      .map ([address, raw]) =>
        user = App.User.findByAttribute('email', address.toLowerCase()) if address
        (user && @fullQuoteHeaderEnsurePrivacy(user, article)) || raw
      .join(', ')

  # Mailbox list parsing keeps quoted display names with commas intact
  #   ('"Doe, John" <j@example.com>'); lists the parser rejects fall back to
  #   comma splitting with the raw address extraction.
  @fullQuoteHeaderParseRecipients: (input) ->
    entries   = emailAddresses.parseAddressList(input) || []
    mailboxes = _.flatten(entries.map((entry) -> entry.addresses || [entry]))
    if !_.isEmpty(mailboxes)
      return mailboxes.map (mailbox) ->
        [mailbox.address, App.Utils.buildEmailAddress(mailbox.name, mailbox.address)]

    elements = input
      .split(/[,;]/)
      .map (elem) ->
        elem.trim()
      .filter (elem) ->
        elem
      .map (elem) =>
        [@fullQuoteHeaderExtractEmail(elem), elem]

    # Without any address there is nothing to scrub - keep the line verbatim.
    return [[null, input.trim()]] if !_.some(elements, ([address]) -> address)

    elements

  # User 1 creates every inbound mail without being its sender - its placeholder
  #   identity must never be rendered, the header value decides.
  @fullQuoteHeaderEnsurePrivacyParseInput: (input) ->
    switch typeof input
      when 'number'
        App.User.find(input) if input isnt 1
      when 'string'
        if email = @fullQuoteHeaderExtractEmail(input)
          App.User.findByAttribute('email', email.toLowerCase())
      when 'object'
        input if input?.id isnt 1

  @fullQuoteHeaderEnsurePrivacy: (input, article, sender = false) =>
    user = @fullQuoteHeaderEnsurePrivacyParseInput(input)
    return if !user

    # Only the sender line may substitute the configured sender format, which can
    #   pair an agent's name with the group address the mail was sent from.
    if sender
      ticket = App.Ticket.find(article.ticket_id)
      return if !ticket

      return user.recipientName(ticket, true, @fullQuoteHeaderRecordedEmailAddress(article))

    # Agents must not fall back to personal data (email, phone, login) when only
    #   their name may be shown. The label also prevents the fallthrough to the raw
    #   header element, which would expose the address again.
    if user.permission('ticket.agent')
      return user.displayNameFromParts() or App.i18n.translatePlain('Agent')

    return App.Utils.buildEmailAddress(user.displayName(), user.email) if user.email

    user.displayName()

  # Prefer the address the mail was actually sent from (stored at send time) -
  #   the ticket may have been moved or the group address changed since.
  @fullQuoteHeaderRecordedEmailAddress: (article) ->
    return if !article.preferences?.email_address_id

    App.EmailAddress.find(article.preferences.email_address_id)

  # Do not allow whitespace, quotes or separators inside the address: display
  #   names can contain email addresses themselves - for users without a name
  #   Zammad builds headers like '"user@example.com" <user@example.com>' - and
  #   a match bleeding into those characters would extract garbage, skip the
  #   user lookup and expose the raw header element.
  @fullQuoteHeaderExtractEmail: (input) ->
    if match = input.match(/<?([^\s"<,;]+@[^>\s",;]+)(>?)/)
      match[1]
