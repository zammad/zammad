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
    #'.editControls':                     'editControls'
    #'.recipient-picker':                 'recipientPicker'
    #'.recipient-list':                   'recipientList'
    #'.recipient-list .list-arrow':       'recipientListArrow'

  events:
    'click .js-toggleVisibility':     'toggleVisibility'
    'click .js-articleTypeItem':      'selectArticleType'
    'click .js-selectedArticleType':  'showSelectableArticleType'
    'click .recipient-picker':        'toggle_recipients'
    'click .recipient-list':          'stopPropagation'
    'click .list-entry-type div':     'change_type'
    'submit .recipient-list form':    'add_recipient'
    'focus .js-textarea':             'openTextarea'
    'input .js-textarea':             'detectEmptyTextarea'
    #'dragenter':                  'onDragenter'
    #'dragleave':                  'onDragleave'
    #'drop':                       'onFileDrop'
    #'change input[type=file]':    'onFilePick'

  constructor: ->
    super

    # gets referenced in @setArticleType
    @type = @defaults['type'] || 'note'
    @articleTypes = [
      {
        name:       'note'
        icon:       'note'
        attributes: []
      },
      {
        name:       'email'
        icon:       'email'
        attributes: ['to','cc']
      },
      {
        name:       'facebook'
        icon:       'facebook'
        attributes: []
      },
      {
        name:       'twitter status'
        icon:       'twitter'
        attributes: []
      },
      {
        name:       'twitter direct-message'
        icon:       'twitter'
        attributes: ['to']
      },
      {
        name:       'phone'
        icon:       'phone'
        attributes: []
      },
    ]
    if @isRole('Customer')
      @type = 'note'
      @articleTypes = [
        {
          name:       'note'
          icon:       'note'
          attributes: []
        },
      ]

    @textareaHeight =
      open:   148
      closed: 20

    @dragEventCounter = 0
    @attachments      = []

    @render()

    if @defaults.body or @isIE10()
      @openTextarea(null, true)

    # set article type and expand text area
    @bind(
      'ui::ticket::setArticleType'
      (data) =>
        return if data.ticket.id isnt @ticket.id
        #@setArticleType(data.type.name)

        @openTextarea(null, true)
        for key, value of data.article
          if key is 'body'
            @$('[data-name="' + key + '"]').html(value)
          else
            @$('[name="' + key + '"]').val(value)

        # preselect article type
        @setArticleType('email')
    )

    # reset new article screen
    @bind(
      'ui::ticket::taskReset'
      (data) =>
        return if data.ticket_id isnt @ticket.id
        @type     = 'note'
        @defaults = {}
        @render()
    )

  isIE10: ->
    Function('/*@cc_on return document.documentMode===10@*/')()

  stopPropagation: (e) ->
    e.stopPropagation()

  release: =>
    if @subscribeIdTextModule
      App.Ticket.unsubscribe(@subscribeIdTextModule)

  render: ->

    ticket = App.Ticket.fullLocal( @ticket.id )

    @html App.view('ticket_zoom/article_new')(
      ticket:       ticket
      articleTypes: @articleTypes
      article:      @defaults
      isCustomer:   @isRole('Customer')
    )
    @setArticleType(@type)

    new App.WidgetAvatar(
      el:       @$('.js-avatar')
      user_id:  App.Session.get('id')
      size:     40
      position: 'right'
      class:    'zIndex-5'
    )

    configure_attributes = [
      { name: 'customer_id', display: 'Recipients', tag: 'user_autocompletion', null: false, placeholder: 'Enter Person or Organization/Company', minLengt: 2, disableCreateUser: false },
    ]

    controller = new App.ControllerForm(
      el: @$('.recipients')
      model:
        configure_attributes: configure_attributes,
    )

    @$('[data-name="body"]').ce({
      mode:      'richtext'
      multiline: true
      maxlength: 40000
    })

    html5Upload.initialize(
      uploadUrl:              App.Config.get('api_path') + '/ticket_attachment_upload',
      dropContainer:          @el.get(0),
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
            console.log('upload start')

          onAborted: =>
            @attachmentPlaceholder.removeClass('hide')
            @attachmentUpload.addClass('hide')

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
            console.log('upload complete', response.data )

          # Called during upload progress, first parameter
          # is decimal value from 0 to 100.
          onProgress: (progress, fileSize, uploadedBytes) =>
            @progressBar.width(parseInt(progress) + '%')
            @progressText.text(parseInt(progress))
            # hide cancel on 90%
            if parseInt(progress) >= 90
              @cancelContainer.addClass('hide')
            console.log('uploadProgress ', parseInt(progress))
        )
    )

    # show text module UI
    if !@isRole('Customer')
      textModule = new App.WidgetTextModule(
        el:       @$('.js-textarea').parent()
        data:
          ticket: ticket
      )
      callback = (ticket) ->
        textModule.reload(
          ticket: ticket
        )
      @subscribeIdTextModule = ticket.subscribe( callback )

  toggle_recipients: =>
    if !@pickRecipientsCatcher
      @show_recipients()
    else
      @hide_recipients()

  show_recipients: ->
    padding = 15

    @recipientPicker.addClass('is-open')
    @recipientList.removeClass('hide')

    pickerDimensions = @recipientPicker.get(0).getBoundingClientRect()
    availableHeight = @recipientPicker.scrollParent().outerHeight()

    top = pickerDimensions.height/2 - @recipientList.height()/2
    bottomDistance = availableHeight - padding - (pickerDimensions.top + top + @recipientList.height())

    if bottomDistance < 0
      top += bottomDistance

    arrowCenter = -top + pickerDimensions.height/2

    @recipientListArrow.css('top', arrowCenter)
    @recipientList.css('top', top)

    $.Velocity.hook(@recipientList, 'transformOriginX', '0')
    $.Velocity.hook(@recipientList, 'transformOriginY', "#{ arrowCenter }px")

    @recipientList.velocity
      properties:
        scale: [ 1, 0 ]
        opacity: [ 1, 0 ]
      options:
        speed: 300
        easing: [ 0.34, 1.61, 0.7, 1 ]

    @pickRecipientsCatcher = new App.ClickCatcher
      holder: @el.offsetParent()
      callback: @hide_recipients
      zIndexScale: 6

  hide_recipients: =>
    @pickRecipientsCatcher.remove()
    @pickRecipientsCatcher = null

    @recipientPicker.removeClass('is-open')

    @recipientList.velocity
      properties:
        scale: [ 0, 1 ]
        opacity: [ 0, 1 ]
      options:
        speed: 300
        easing: [ 500, 20 ]
        complete: -> @recipientList.addClass('hide')

  change_type: (e) ->
    $(e.target).addClass('active').siblings('.active').removeClass('active')
    # store $(this).data('value')

  add_recipient: (e) ->
    e.stopPropagation()
    e.preventDefault()
    console.log 'add recipient', e
    # store recipient

  toggleVisibility: ->
    if @articleNewEdit.hasClass 'is-public'
      @articleNewEdit
        .removeClass 'is-public'
        .addClass 'is-internal'

      @$('[name=internal]').val 'true'
    else
      @articleNewEdit
        .addClass 'is-public'
        .removeClass 'is-internal'


      @$('[name=internal]').val ''

  showSelectableArticleType: =>
    @el.find('.js-articleTypes').removeClass('is-hidden')

    @selectTypeCatcher = new App.ClickCatcher
      holder:      @el.offsetParent()
      callback:    @hideSelectableArticleType
      zIndexScale: 6

  selectArticleType: (e) =>
    articleTypeToSet = $(e.target).closest('.pop-selectable').data('value')
    @setArticleType( articleTypeToSet )
    @hideSelectableArticleType()

    @selectTypeCatcher.remove()
    @selectTypeCatcher = null

  hideSelectableArticleType: =>
    @el.find('.js-articleTypes').addClass('is-hidden')

  setArticleType: (type) ->
    typeIcon = @$('.js-selectedType')
    @type = type
    @$('[name=type]').val(type)
    @articleNewEdit.attr('data-type', type)
    typeIcon.find('use').attr 'xlink:href', "#icon-#{@type}"

    # show/hide attributes
    for articleType in @articleTypes
      if articleType.name is type
        @$('.form-group').addClass('hide')
        for name in articleType.attributes
          @$("[name=#{name}]").closest('.form-group').removeClass('hide')

    # check if signature need to be added
    body      = @$('[data-name=body]').html() || ''
    signature = undefined
    if @ticket.group.signature_id
      signature = App.Signature.find( @ticket.group.signature_id )
    if signature && signature.body && @type is 'email'
      signatureFinished = App.Utils.text2html(
        App.Utils.replaceTags( signature.body, { user: App.Session.get(), ticket: @ticket } )
      )
      if App.Utils.signatureCheck( body, signatureFinished )
        if !App.Utils.lastLineEmpty(body)
          body = body + '<br>'
        body = body + "<div data-signature=\"true\" data-signature-id=\"#{signature.id}\">#{signatureFinished}</div>"
        @$('[data-name=body]').html(body)

    # remove old signature
    else
      @$('[data-name=body]').find('[data-signature=true]').remove()

  detectEmptyTextarea: =>
    if !@textarea.text().trim()
      @addTextareaCatcher()
    else
      @removeTextareaCatcher()

  openTextarea: (event, withoutAnimation) =>
    if !@articleNewEdit.hasClass('is-open')
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
          complete: => @addTextareaCatcher()

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

  addTextareaCatcher: =>
    if @articleNewEdit.is(':visible')
      @textareaCatcher = new App.ClickCatcher
        holder:      @articleNewEdit.offsetParent()
        callback:    @closeTextarea
        zIndexScale: 4

  removeTextareaCatcher: ->
    return if !@textareaCatcher
    @textareaCatcher.remove()
    @textareaCatcher = null

  closeTextarea: =>
    @removeTextareaCatcher()
    if !@textarea.text().trim() && !@attachments.length && not @isIE10()

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
          data:  JSON.stringify( { store_id: store_id } ),
          processData: false
        )

        # remove attachment from dom
        element = $(e.currentTarget).closest('.attachments')
        $(e.currentTarget).closest('.attachment').remove()
        # empty .attachment (remove spaces) to keep css working, thanks @mrflix :-o
        if element.find('.attachment').length == 0
          element.empty()
    )
