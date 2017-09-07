class App.TicketZoomArticleNew extends App.Controller
  elements:
    '.js-textarea':                       'textarea'
    '.attachmentPlaceholder':             'attachmentPlaceholder'
    '.attachmentPlaceholder-inputHolder': 'attachmentInputHolder'
    '.attachmentPlaceholder-hint':        'attachmentHint'
    '.article-add':                       'articleNewEdit'
    '.attachments':                       'attachmentsHolder'
    '.attachmentUpload':                  'attachmentUpload'
    '.attachmentUpload-progressBar':      'progressBar'
    '.js-percentage':                     'progressText'
    '.js-cancel':                         'cancelContainer'
    '.textBubble':                        'textBubble'
    '.editControls-item':                 'editControlItem'
    '.js-letterCount':                    'letterCount'
    '.js-signature':                      'signature'

  events:
    'click .js-toggleVisibility':    'toggleVisibility'
    'click .js-articleTypeItem':     'selectArticleType'
    'click .js-selectedArticleType': 'showSelectableArticleType'
    'click .js-mail-inputs':         'stopPropagation'
    'click .js-writeArea':           'propagateOpenTextarea'
    'click .list-entry-type div':    'changeType'
    'focus .js-textarea':            'openTextarea'
    'input .js-textarea':            'updateLetterCount'

  constructor: ->
    super

    @internalSelector = true
    @type = @defaults['type'] || 'note'
    @setPossibleArticleTypes()

    if @permissionCheck('ticket.customer')
      @internalSelector = false

    @textareaHeight =
      open:   148
      closed: 20

    @dragEventCounter = 0
    @attachments      = []

    @render()

    if @defaults.body or @isIE10()
      @openTextarea(null, true)

    # set article type and expand text area
    @bind('ui::ticket::setArticleType', (data) =>
      return if data.ticket.id.toString() isnt @ticket_id.toString()

      @openTextarea(null, true)
      for key, value of data.article
        if key is 'body'
          @$('[data-name="' + key + '"]').html(value)
        else
          @$('[name="' + key + '"]').val(value).trigger('change')

      # preselect article type
      @setArticleType(data.type.name, data.signaturePosition)

      # set focus at end of field
      if data.position is 'end'
        @placeCaretAtEnd(@textarea.get(0))
        return

      # set focus into field
      @textarea.focus()
    )

    # reset new article screen
    @bind('ui::ticket::taskReset', (data) =>
      return if data.ticket_id.toString() isnt @ticket_id.toString()
      @type     = 'note'
      @defaults = {}
      @render()
    )

    # rerender, e. g. on language change
    @bind('ui:rerender', =>
      @render()
    )

  setPossibleArticleTypes: =>
    possibleArticleType =
      note: true
      phone: true
    if @ticket && @ticket.create_article_type_id
      articleTypeCreate = App.TicketArticleType.find(@ticket.create_article_type_id).name
      if articleTypeCreate is 'twitter status'
        possibleArticleType['twitter status'] = true
      else if articleTypeCreate is 'twitter direct-message'
        possibleArticleType['twitter direct-message'] = true
      else if articleTypeCreate is 'email'
        possibleArticleType['email'] = true
      else if articleTypeCreate is 'facebook feed post'
        possibleArticleType['facebook feed comment'] = true
      else if articleTypeCreate is 'telegram personal-message'
        possibleArticleType['telegram personal-message'] = true
    if @ticket && @ticket.customer_id
      customer = App.User.find(@ticket.customer_id)
      if customer.email
        possibleArticleType['email'] = true

    # gets referenced in @setArticleType
    @articleTypes = []
    if possibleArticleType.note
      internal = @Config.get('ui_ticket_zoom_article_note_new_internal')
      @articleTypes.push {
        name:       'note'
        icon:       'note'
        attributes: []
        internal:   internal,
        features:   ['attachment']
      }
    if possibleArticleType.email
      attributes = ['to', 'cc', 'subject']
      if !@Config.get('ui_ticket_zoom_article_email_subject')
        attributes = ['to', 'cc']
      @articleTypes.push {
        name:       'email'
        icon:       'email'
        attributes: attributes
        internal:   false,
        features:   ['attachment']
      }
    if possibleArticleType['facebook feed comment']
      @articleTypes.push {
        name:       'facebook feed comment'
        icon:       'facebook'
        attributes: []
        internal:   false,
        features:   []
      }
    if possibleArticleType['twitter status']
      attributes = ['body:limit', 'body:initials']
      if !@Config.get('ui_ticket_zoom_article_twitter_initials')
        attributes = ['body:limit']
      @articleTypes.push {
        name:              'twitter status'
        icon:              'twitter'
        attributes:        []
        internal:          false,
        features:          ['body:limit', 'body:initials']
        maxTextLength:     140
        warningTextLength: 30
      }
    if possibleArticleType['twitter direct-message']
      attributes = ['body:limit', 'body:initials']
      if !@Config.get('ui_ticket_zoom_article_twitter_initials')
        attributes = ['body:limit']
      @articleTypes.push {
        name:              'twitter direct-message'
        icon:              'twitter'
        attributes:        ['to']
        internal:          false,
        features:          ['body:limit', 'body:initials']
        maxTextLength:     10000
        warningTextLength: 500
      }
    if possibleArticleType.phone
      @articleTypes.push {
        name:       'phone'
        icon:       'phone'
        attributes: []
        internal:   false,
        features:   ['attachment']
      }
    if possibleArticleType['telegram personal-message']
      @articleTypes.push {
        name:              'telegram personal-message'
        icon:              'telegram'
        attributes:        []
        internal:          false,
        features:          ['attachment']
        maxTextLength:     10000
        warningTextLength: 5000
      }

    if @permissionCheck('ticket.customer')
      @type = 'note'
      @articleTypes = [
        {
          name:       'note'
          icon:       'note'
          attributes: []
          internal:   false,
          features:   ['attachment']
        },
      ]

  placeCaretAtEnd: (el) ->
    el.focus()
    if typeof window.getSelection isnt 'undefined' && typeof document.createRange isnt 'undefined'
      range = document.createRange()
      range.selectNodeContents(el)
      range.collapse(false)
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
      return
    if typeof document.body.createTextRange isnt 'undefined'
      textRange = document.body.createTextRange()
      textRange.moveToElementText(el)
      textRange.collapse(false)
      textRange.select()

  isIE10: ->
    Function('/*@cc_on return document.documentMode===10@*/')()

  release: =>
    if @subscribeIdTextModule
      App.Ticket.unsubscribe(@subscribeIdTextModule)

    $(window).off 'click.ticket-zoom-select-type'
    $(window).on 'click.ticket-zoom-textarea'

  render: ->

    ticket = App.Ticket.fullLocal(@ticket_id)

    @html App.view('ticket_zoom/article_new')(
      ticket:           ticket
      articleTypes:     @articleTypes
      article:          @defaults
      form_id:          @form_id
      isCustomer:       @permissionCheck('ticket.customer')
      internalSelector: @internalSelector
    )
    @setArticleType(@type)

    new App.WidgetAvatar(
      el:        @$('.js-avatar')
      object_id: App.Session.get('id')
      size:      40
      position:  'right'
    )

    configure_attributes = [
      { name: 'customer_id', display: 'Recipients', tag: 'user_autocompletion', null: false, placeholder: 'Enter Person or Organization/Company', minLengt: 2, disableCreateObject: false },
    ]

    controller = new App.ControllerForm(
      el: @$('.recipients')
      model:
        configure_attributes: configure_attributes,
    )

    @$('[data-name="body"]').ce({
      mode:      'richtext'
      multiline: true
      maxlength: 50000
    })

    html5Upload.initialize(
      uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload',
      dropContainer:          @$('.article-add').get(0),
      cancelContainer:        @cancelContainer,
      inputField:             @$('.article-attachment input').get(0),
      key:                    'File',
      data:                   { form_id: @form_id },
      maxSimultaneousUploads: 1,
      onFileAdded:            (file) =>

        file.on(

          onStart: =>
            @attachmentPlaceholder.addClass('hide')
            @attachmentUpload.removeClass('hide')
            @cancelContainer.removeClass('hide')

          onAborted: =>
            @attachmentPlaceholder.removeClass('hide')
            @attachmentUpload.addClass('hide')
            @$('.article-attachment input').val('')

          # Called after received response from the server
          onCompleted: (response) =>

            response = JSON.parse(response)
            @attachments.push response.data

            @attachmentPlaceholder.removeClass('hide')
            @attachmentUpload.addClass('hide')

            # reset progress bar
            @progressBar.width(parseInt(0) + '%')
            @progressText.text('')

            @renderAttachment(response.data)
            @$('.article-attachment input').val('')

          # Called during upload progress, first parameter
          # is decimal value from 0 to 100.
          onProgress: (progress, fileSize, uploadedBytes) =>
            @progressBar.width(parseInt(progress) + '%')
            @progressText.text(parseInt(progress))
            # hide cancel on 90%
            if parseInt(progress) >= 90
              @cancelContainer.addClass('hide')
        )
    )

    # show text module UI
    if !@permissionCheck('ticket.customer')
      textModule = new App.WidgetTextModule(
        el: @$('.js-textarea').parent()
        data:
          ticket: ticket
          user: App.Session.get()
          config: App.Config.all()
      )
      callback = (ticket) ->
        textModule.reload(
          ticket: ticket
          user: App.Session.get()
        )
      if !@subscribeIdTextModule
        @subscribeIdTextModule = ticket.subscribe(callback)

  params: =>
    params = @formParam( @$('.article-add') )

    if params.body
      params.from         = @Session.get().displayName()
      params.ticket_id    = @ticket_id
      params.form_id      = @form_id
      params.content_type = 'text/html'

      if @permissionCheck('ticket.customer')
        sender           = App.TicketArticleSender.findByAttribute('name', 'Customer')
        type             = App.TicketArticleType.findByAttribute('name', 'web')
        params.type_id   = type.id
        params.sender_id = sender.id
      else
        sender           = App.TicketArticleSender.findByAttribute('name', 'Agent')
        type             = App.TicketArticleType.findByAttribute('name', params['type'])
        params.sender_id = sender.id
        params.type_id   = type.id

    if params.internal
      params.internal = true
    else
      params.internal = false

    if params.type is 'twitter status'
      App.Utils.htmlRemoveRichtext(@$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    if params.type is 'twitter direct-message'
      App.Utils.htmlRemoveRichtext(@$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    if params.type is 'facebook feed comment'
      App.Utils.htmlRemoveRichtext(@$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    if params.type is 'telegram personal-message'
      App.Utils.htmlRemoveRichtext(@$('[data-name=body]'), false)
      params.content_type = 'text/plain'
      params.body = App.Utils.html2text(params.body, true)

    # add initals?
    for articleType in @articleTypes
      if articleType.name is @type
        if _.contains(articleType.features, 'body:initials')
          if params.content_type is 'text/html'
            params.body = "#{params.body}</br>#{@signature.text()}"
          else
            params.body = "#{params.body}\n#{@signature.text()}"
          break

    params

  validate: =>
    params = @params()

    # check if attachment exists but no body
    attachmentCount = @$('.article-add .textBubble .attachments .attachment').length
    if !params.body && attachmentCount > 0
      new App.ControllerModal(
        head: 'Text missing'
        buttonCancel: 'Cancel'
        buttonCancelClass: 'btn--danger'
        buttonSubmit: false
        message: 'Please fill also some text in!'
        shown: true
        small: true
        container: @el.closest('.content')
      )
      return false

    # validate email params
    if params.type is 'email'

      # check if recipient exists
      if !params.to && !params.cc
        new App.ControllerModal(
          head: 'Text missing'
          buttonCancel: 'Cancel'
          buttonCancelClass: 'btn--danger'
          buttonSubmit: false
          message: 'Need recipient in "To" or "Cc".'
          shown: true
          small: true
          container: @el.closest('.content')
        )
        return false

      # check if message exists
      if !params.body
        new App.ControllerModal(
          head: 'Text missing'
          buttonCancel: 'Cancel'
          buttonCancelClass: 'btn--danger'
          buttonSubmit: false
          message: 'Text needed'
          shown: true
          small: true
          container: @el.closest('.content')
        )
        return false

    # check attachment
    if params.body && attachmentCount < 1
      matchingWord = App.Utils.checkAttachmentReference(params.body)
      if matchingWord
        if !confirm(App.i18n.translateContent('You use %s in text but no attachment is attached. Do you want to continue?', matchingWord))
          return false

    if params.type is 'twitter status'
      textLength = @maxTextLength - App.Utils.textLengthWithUrl(params.body)
      return false if textLength < 0

    if params.type is 'twitter direct-message'
      textLength = @maxTextLength - App.Utils.textLengthWithUrl(params.body)
      return false if textLength < 0

    true

  changeType: (e) ->
    $(e.target).addClass('active').siblings('.active').removeClass('active')

  toggleVisibility: (e, internal) ->
    e.stopPropagation()
    if @articleNewEdit.hasClass('is-public')
      @setArticleInternal(true)
    else
      @setArticleInternal(false)

  showSelectableArticleType: (event) =>
    event.stopPropagation()
    @el.find('.js-articleTypes').removeClass('is-hidden')
    $(window).on 'click.ticket-zoom-select-type', @hideSelectableArticleType

  selectArticleType: (event) =>
    event.stopPropagation()
    articleTypeToSet = $(event.target).closest('.pop-selectable').data('value')
    @setArticleType(articleTypeToSet)
    @hideSelectableArticleType()

    $(window).off 'click.ticket-zoom-select-type'

  hideSelectableArticleType: =>
    @el.find('.js-articleTypes').addClass('is-hidden')

  setArticleInternal: (internal) =>
    if internal is true
      @articleNewEdit
        .removeClass('is-public')
        .addClass('is-internal')

      @$('[name=internal]').val('true')
      return

    @articleNewEdit
      .addClass('is-public')
      .removeClass('is-internal')

    @$('[name=internal]').val('')

  setArticleType: (type, signaturePosition = 'bottom') =>
    wasScrolledToBottom = @isScrolledToBottom()
    @type = type
    @$('[name=type]').val(type).trigger('change')
    @articleNewEdit.attr('data-type', type)
    @$('.js-selectableTypes').addClass('hide').filter("[data-type='#{type}']").removeClass('hide')

    @setPossibleArticleTypes()

    # get config
    config = {}
    for articleTypeConfig in @articleTypes
      if articleTypeConfig.name is type
        config = articleTypeConfig

    if config
      if config.internal
        @setArticleInternal(true)
      else
        @setArticleInternal(false)

    # detect current signature (use current group_id, if not set, use ticket.group_id)
    ticketCurrent = App.Ticket.fullLocal(@ticket_id)
    group_id = ticketCurrent.group_id
    task = App.TaskManager.get(@task_key)
    if task && task.state && task.state.ticket && task.state.ticket.group_id
      group_id = task.state.ticket.group_id
    group = App.Group.find(group_id)
    signature = undefined
    if group && group.signature_id
      signature = App.Signature.find(group.signature_id)

    # add/replace signature
    if signature && signature.body && @type is 'email'

      # if signature has changed, remove it
      signature_id = @$('[data-signature=true]').data('signature-id')
      if signature_id && signature_id.toString() isnt signature.id.toString()
        @$('[data-name=body] [data-signature="true"]').remove()

      # apply new signature
      signatureFinished = App.Utils.replaceTags(signature.body, { user: App.Session.get(), ticket: ticketCurrent, config: App.Config.all() })

      body = @$('[data-name=body]')
      if App.Utils.signatureCheck(body.html() || '', signatureFinished)
        if !App.Utils.htmlLastLineEmpty(body)
          body.append('<br><br>')
        signature = $("<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>")
        App.Utils.htmlStrip(signature)
        if signaturePosition is 'top'
          body.prepend(signature)
        else
          body.append(signature)
        @$('[data-name=body]').replaceWith(body)

    # remove old signature
    else
      @$('[data-name=body] [data-signature=true]').remove()

    # remove richtext
    if @type is 'twitter status' || @type is 'twitter direct-message' || @type is 'telegram personal-message'
      rawHTML = @$('[data-name=body]').html()
      cleanHTML = App.Utils.htmlRemoveRichtext(rawHTML)
      if cleanHTML && cleanHTML.html() != rawHTML
        @$('[data-name=body]').html(cleanHTML)

    # show/hide attributes/features
    @maxTextLength = undefined
    @warningTextLength = undefined
    for articleType in @articleTypes
      if articleType.name is type
        @$('.form-group').addClass('hide')
        for name in articleType.attributes
          @$("[name=#{name}]").closest('.form-group').removeClass('hide')
        @$('.article-attachment, .attachments, .js-textSizeLimit').addClass('hide')
        for name in articleType.features
          if name is 'attachment'
            @$('.article-attachment, .attachments').removeClass('hide')
          if name is 'body:initials'
            @updateInitials()
          if name is 'body:limit'
            @maxTextLength = articleType.maxTextLength
            @warningTextLength = articleType.warningTextLength
            @delay(@updateLetterCount, 600)
            @$('.js-textSizeLimit').removeClass('hide')

    # convert remote src images to data uri
    @$('[data-name=body] img').each( (i,image) ->
      $image = $(image)
      src = $image.attr('src')
      if !_.isEmpty(src) && !src.match(/^data:image/i)
        canvas = document.createElement('canvas')
        canvas.width = image.width
        canvas.height = image.height
        ctx = canvas.getContext('2d')
        ctx.drawImage(image, 0, 0)
        dataURL = canvas.toDataURL()
        $image.attr('src', dataURL)
    )

    @scrollToBottom() if wasScrolledToBottom

  isScrolledToBottom: ->
    return @el.scrollParent().scrollTop() + @el.scrollParent().height() is @el.scrollParent().prop('scrollHeight')

  scrollToBottom: ->
    @el.scrollParent().scrollTop @el.scrollParent().prop('scrollHeight')

  propagateOpenTextarea: (event) ->
    event.stopPropagation()
    @textarea.focus()

  updateLetterCount: =>
    return if !@maxTextLength
    return if !@warningTextLength
    params = @params()
    textLength = App.Utils.textLengthWithUrl(params.body)
    textLength = @maxTextLength - textLength
    className = switch
      when textLength < 0 then 'label-danger'
      when textLength < @warningTextLength then 'label-warning'
      else ''

    @letterCount
      .text textLength
      .removeClass 'label-danger label-warning'
      .addClass className

  updateInitials: (value) =>
    if value is undefined
      value = "/#{App.User.find(@Session.get('id')).initials()}"
    @signature.text(value)

  openTextarea: (event, withoutAnimation) =>
    if event
      event.stopPropagation()
    if @articleNewEdit.hasClass('is-open')
      return

    duration = 300

    if withoutAnimation
      duration = 0

    @articleNewEdit.addClass('is-open')

    @textarea.velocity
      properties:
        minHeight: "#{ @textareaHeight.open - 38 }px"
      options:
        duration: duration
        easing: 'easeOutQuad'
        complete: => $(window).on 'click.ticket-zoom-textarea', @closeTextarea

    @textBubble.velocity
      properties:
        paddingBottom: 28
      options:
        duration: duration
        easing: 'easeOutQuad'

    # scroll to bottom
    @textarea.velocity 'scroll',
      container: @textarea.scrollParent()
      offset: 99999
      duration: 300
      easing: 'easeOutQuad'
      queue: false

    @editControlItem
      .removeClass('is-hidden')
      .velocity
        properties:
          opacity: [ 1, 0 ]
          translateX: [ 0, 20 ]
          translateZ: 0
        options:
          duration: 300
          stagger: 50
          drag: true

    # move attachment text to the left bottom (bottom happens automatically)
    @attachmentPlaceholder.velocity
      properties:
        translateX: -@attachmentInputHolder.position().left + 'px'
      options:
        duration: duration
        easing: 'easeOutQuad'

    @attachmentHint.velocity
      properties:
        opacity: 0
      options:
        duration: duration

  closeTextarea: =>
    if !@textarea.text().trim() && !@attachments.length && not @isIE10()
      $(window).off 'click.ticket-zoom-textarea'

      @textarea.velocity
        properties:
          minHeight: "#{ @textareaHeight.closed }px"
        options:
          duration: 300
          easing: 'easeOutQuad'
          complete: => @articleNewEdit.removeClass('is-open')

      @textBubble.velocity
        properties:
          paddingBottom: 10
        options:
          duration: 300
          easing: 'easeOutQuad'

      @attachmentPlaceholder.velocity
        properties:
          translateX: 0
        options:
          duration: 300
          easing: 'easeOutQuad'

      @attachmentHint.velocity
        properties:
          opacity: 1
        options:
          duration: 300

      @editControlItem
        .velocity
          properties:
            opacity: [ 0, 1 ]
            translateX: [ 20, 0 ]
            translateZ: 0
          options:
            duration: 100
            stagger: 50
            drag: true
            complete: (elements) -> $(elements).addClass('is-hidden')

  onDragenter: (event) =>
    # on the first event,
    # open textarea (it will only open if its closed)
    @openTextarea() if @dragEventCounter is 0

    @dragEventCounter++
    @articleNewEdit.parent().addClass('is-dropTarget')

  onDragleave: (event) =>
    @dragEventCounter--

    @articleNewEdit.parent().removeClass('is-dropTarget') if @dragEventCounter is 0

  renderAttachment: (file) =>
    @attachmentsHolder.append App.view('generic/attachment_item')
      fileName: file.filename
      fileSize: @humanFileSize( file.size )
      store_id: file.store_id
    @attachmentsHolder.on(
      'click'
      "[data-id=#{file.store_id}]", (e) =>
        @attachments = _.filter(
          @attachments,
          (item) ->
            return if item.id isnt file.store_id
            item
        )
        store_id = $(e.currentTarget).data('id')

        # delete attachment from storage
        App.Ajax.request(
          type:  'DELETE'
          url:   App.Config.get('api_path') + '/ticket_attachment_upload'
          data:  JSON.stringify(store_id: store_id)
          processData: false
        )

        # remove attachment from dom
        element = $(e.currentTarget).closest('.attachments')
        $(e.currentTarget).closest('.attachment').remove()
        # empty .attachment (remove spaces) to keep css working, thanks @mrflix :-o
        if element.find('.attachment').length == 0
          element.empty()
    )
