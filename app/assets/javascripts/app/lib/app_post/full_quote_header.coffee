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

    @fullQuoteHeaderEnsurePrivacy(user_id) || @fullQuoteHeaderEnsurePrivacy(article.from) || article.from

  @fullQuoteHeaderForwardTo: (article) ->
    if article.type.name is 'email' || article.type.name is 'web'
      @fullQuoteHeaderEnsurePrivacy(article.to) || article.to
    else if article.sender.name is 'Customer' && article.type.name is 'phone'
      if email_address_id = App.Group.findByAttribute('name', article.to)?.email_address_id
        App.EmailAddress.find(email_address_id).displayName()
      else
        article.to
    else if article.sender.name is 'Agent' && article.type.name is 'phone'
      ticket = App.Ticket.find article.ticket_id
      @fullQuoteHeaderEnsurePrivacy(ticket.customer_id) || @fullQuoteHeaderEnsurePrivacy(article.to) || article.to
    else
      article.to

  @fullQuoteHeaderForwardCC: (article) ->
    return if !article.cc

    article
      .cc
      .split(',')
      .map (elem) ->
        elem.trim()
      .map (elem) =>
        @fullQuoteHeaderEnsurePrivacy(elem) || elem
      .join(', ')

  @fullQuoteHeaderEnsurePrivacyParseInput: (input) ->
    switch typeof input
      when 'number'
        App.User.find input
      when 'string'
        if email = @fullQuoteHeaderExtractEmail(input)
          App.User.findByAttribute('email', email)
      when 'object'
        input

  @fullQuoteHeaderEnsurePrivacy: (input) =>
    user = @fullQuoteHeaderEnsurePrivacyParseInput(input)

    return if !user

    output = "#{user.displayName()}"

    if !user.permission('ticket.agent') && user.email
      output += " <#{user.email}>"

    output

  @fullQuoteHeaderExtractEmail: (input) ->
    if match = input.match(/<?(\S+@\S[^>]+)(>?)/)
      match[1]
