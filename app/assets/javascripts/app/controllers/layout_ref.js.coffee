class Index extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/index')()

App.Config.set( 'layout_ref', Index, 'Routes' )


class Content extends App.ControllerContent
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganisationMembers'
    'click .js-organisation':                 'showOrganisationMembers'
    'click .js-back':                         'hideOrganisationMembers'

  constructor: ->
    super
    @render()

    @dragEventCounter = 0
    @attachments = []

    for avatar in @$('.user.avatar')
      avatar = $(avatar)
      size = if avatar.hasClass('big') then 50 else 40
      @createUniqueAvatar avatar, size, avatar.data('firstname'), avatar.data('lastname'), avatar.data('userid')

  createUniqueAvatar: (holder, size, firstname, lastname, id) ->
    width = 300
    height = 226

    holder.addClass 'unique'

    rng = new Math.seedrandom(id);
    x = rng() * (width - size)
    y = rng() * (height - size)
    holder.css('background-position', "-#{ x }px -#{ y }px")

    holder.text(firstname[0] + lastname[0])

  render: ->
    @html App.view('layout_ref/content')()

  showOrganisationMembers: (e) =>
    e.stopPropagation()

    listEntry = $(e.currentTarget)
    organisationId = listEntry.data('organisation-id')

    @recipientList = @$('.recipientList')
    @organisationList = @$("##{ organisationId }")

    # move organisation-list to the right and slide it in

    $.Velocity.hook(@organisationList, 'translateX', '100%')
    @organisationList.removeClass('hide')

    @organisationList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # fade out list

    @recipientList.velocity
      properties:
        translateX: '-100%'
      options:
        speed: 300
        complete: => @recipientList.height(@organisationList.height())

  hideOrganisationMembers: (e) =>
    e && e.stopPropagation()

    return if !@organisationList

    # fade list back in

    @recipientList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # reset list height

    @recipientList.height('')

    # slide out organisation-list and hide it
    @organisationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organisationList.addClass('hide')

App.Config.set( 'layout_ref/content', Content, 'Routes' )


class CommunicationOverview extends App.ControllerContent

  constructor: ->
    super
    @render()

    @bindScrollPageHeader()

  bindScrollPageHeader: ->
    pageHeader = @$('.page-header')
    scrollHolder = pageHeader.scrollParent()
    scrollBody = scrollHolder.get(0).scrollHeight - scrollHolder.height()

    if scrollBody > pageHeader.height()
      skrollr.init
        forceHeight: false
        holder: scrollHolder.get(0)

  render: ->
    @html App.view('layout_ref/communication_overview')()

App.Config.set( 'layout_ref/communication_overview', CommunicationOverview, 'Routes' )


class LayoutRefCommunicationReply extends App.ControllerContent
  elements:
    '.js-textarea' :                'textarea'
    '.attachmentPlaceholder':       'attachmentPlaceholder'
    '.attachmentPlaceholder-inputHolder': 'attachmentInputHolder'
    '.attachmentPlaceholder-hint':  'attachmentHint'
    '.ticket-edit':                 'ticketEdit'
    '.attachments':                 'attachmentsHolder'
    '.attachmentUpload':            'attachmentUpload'
    '.attachmentUpload-progressBar':'progressBar'
    '.js-percentage':               'progressText'

  events:
    'focus .js-textarea':                     'open_textarea'
    'input .js-textarea':                     'detect_empty_textarea'
    'dragenter':                              'onDragenter'
    'dragleave':                              'onDragleave'
    'drop':                                   'onFileDrop'
    'change input[type=file]':                'onFilePick'

  constructor: ->
    super

    if @content is 'no_content'
      @content = ''
    else if @content is 'content'
      @content = "some content la la la la"
    else
      @content = "some\nmultiline content\n1\n2\n3"

    @render()

    @textareaHeight =
      open: 148
      closed: 20

    @open_textarea(null, true) if @content

    @dragEventCounter = 0
    @attachments = []

  render: ->
    @html App.view('layout_ref/communication_reply')(
      content: @content
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 2500
    })

    @$('[contenteditable]').textmodule()

  detect_empty_textarea: =>
    if !@textarea.text()
      @add_textarea_catcher()
    else
      @remove_textarea_catcher()

  open_textarea: (event, withoutAnimation) =>
    if !@ticketEdit.hasClass('is-open')
      duration = 300

      if withoutAnimation
        duration = 0

      @ticketEdit.addClass('is-open')

      @textarea.velocity
        properties:
          minHeight: "#{ @textareaHeight.open - 38 }px"
          marginBottom: 38
        options:
          duration: duration
          easing: 'easeOutQuad'
          complete: => @add_textarea_catcher()

      # scroll to bottom
      # @textarea.velocity "scroll",
      #   container: @textarea.scrollParent()
      #   offset: 99999
      #   duration: 300
      #   easing: 'easeOutQuad'
      #   queue: false

      # @editControlItem.velocity "transition.slideRightIn",
      #   duration: 300
      #   stagger: 50
      #   drag: true

      # move attachment text to the left bottom (bottom happens automatically)

      @attachmentPlaceholder.velocity
        properties:
          translateX: -@attachmentInputHolder.position().left + "px"
        options:
          duration: duration
          easing: 'easeOutQuad'

      @attachmentHint.velocity
        properties:
          opacity: 0
        options:
          duration: duration

  add_textarea_catcher: ->
    @textareaCatcher = new App.clickCatcher
      holder: @ticketEdit.offsetParent()
      callback: @close_textarea
      zIndexScale: 4

  remove_textarea_catcher: ->
    return if !@textareaCatcher
    @textareaCatcher.remove()
    @textareaCatcher = null

  close_textarea: =>
    @remove_textarea_catcher()
    if !@textarea.text() && !@attachments.length

      @textarea.velocity
        properties:
          minHeight: "#{ @textareaHeight.closed }px"
          marginBottom: 0
        options:
          duration: 300
          easing: 'easeOutQuad'
          complete: => @ticketEdit.removeClass('is-open')

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

      # @editControlItem.css('display', 'none')

  onDragenter: (event) =>
    # on the first event,
    # open textarea (it will only open if its closed)
    @open_textarea() if @dragEventCounter is 0

    @dragEventCounter++
    @ticketEdit.addClass('is-dropTarget')

  onDragleave: (event) =>
    @dragEventCounter--

    @ticketEdit.removeClass('is-dropTarget') if @dragEventCounter is 0

  onFileDrop: (event) =>
    event.preventDefault()
    event.stopPropagation()
    files = event.originalEvent.dataTransfer.files
    @ticketEdit.removeClass('is-dropTarget')

    @queueUpload(files)

  onFilePick: (event) =>
    @open_textarea()
    @queueUpload(event.target.files)

  queueUpload: (files) ->
    @uploadQueue ?= []

    # add files
    for file in files
      @uploadQueue.push(file)

    @workOfUploadQueue()

  workOfUploadQueue: =>
    if !@uploadQueue.length
      return

    file = @uploadQueue.shift()
    # console.log "working of", file, "from", @uploadQueue
    @fakeUpload file.name, file.size, @workOfUploadQueue

  humanFileSize: (size) =>
    i = Math.floor( Math.log(size) / Math.log(1024) )
    return ( size / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'kB', 'MB', 'GB', 'TB'][i]

  updateUploadProgress: (progress) =>
    @progressBar.width(progress + "%")
    @progressText.text(progress)

    if progress is 100
      @attachmentPlaceholder.removeClass('hide')
      @attachmentUpload.addClass('hide')

  fakeUpload: (fileName, fileSize, callback) ->
    @attachmentPlaceholder.addClass('hide')
    @attachmentUpload.removeClass('hide')

    progress = 0;
    duration = fileSize / 1024

    for i in [0..100]
      setTimeout @updateUploadProgress, i*duration/100 , i

    setTimeout (=> 
      callback()
      @renderAttachment(fileName, fileSize)
    ), duration

  renderAttachment: (fileName, fileSize) =>
    @attachments.push([fileName, fileSize])
    @attachmentsHolder.append App.view('ticket_zoom/attachment')
      fileName: fileName
      fileSize: @humanFileSize(fileSize)


App.Config.set( 'layout_ref/communication_reply/:content', LayoutRefCommunicationReply, 'Routes' )



class ContentSidebarRight extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right')()

App.Config.set( 'layout_ref/content_sidebar_right', ContentSidebarRight, 'Routes' )


class ContentSidebarRightSidebarOptional extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right_sidebar_optional')()

App.Config.set( 'layout_ref/content_sidebar_right_sidebar_optional', ContentSidebarRightSidebarOptional, 'Routes' )


class ModalForm extends App.ControllerModal
  constructor: ->
    super
    @head  = '123 some title'
    @cancel = true
    @button = true

    @render()

  render: ->
    controller = new App.ControllerForm(
      model: App.User
      autofocus: true
    )
    @el = controller.form

    @show()

  onHide: =>
    window.history.back()

  onSubmit: (e) =>
    e.preventDefault()
    params = App.ControllerForm.params( $(e.target).closest('form') )
    console.log('params', params)

App.Config.set( 'layout_ref/modal_form', ModalForm, 'Routes' )


class ModalText extends App.ControllerModal
  constructor: ->
    super
    @head = '123 some title'

    @render()

  render: ->
    @html App.view('layout_ref/content')()

    @show()

  onHide: =>
    window.history.back()

App.Config.set( 'layout_ref/modal_text', ModalText, 'Routes' )



class ContentSidebarTabsRight extends App.ControllerContent
  elements:
    '.tabsSidebar'  : 'sidebar'

  constructor: ->
    super
    @render()

    changeCustomerTicket = ->
      alert('change customer ticket')

    editCustomerTicket = ->
      alert('edit customer ticket')

    changeCustomerCustomer = ->
      alert('change customer customer')

    editCustomerCustomer = ->
      alert('edit customer customer')


    items = [
        head: 'Ticket Settings'
        name: 'ticket'
        icon: 'message'
        callback: (el) ->
          el.html('some ticket')
        actions: [
            name:  'Change Customer'
            class: 'glyphicon glyphicon-transfer'
            callback: changeCustomerTicket
          ,
            name:  'Edit Customer'
            class: 'glyphicon glyphicon-edit'
            callback: editCustomerTicket
        ]
      ,
        head: 'Customer'
        name: 'customer'
        icon: 'person'
        callback: (el) ->
          el.html('some customer')
        actions: [
            name:  'Change Customer'
            class: 'glyphicon glyphicon-transfer'
            callback: changeCustomerCustomer
          ,
            name:  'Edit Customer'
            class: 'glyphicon glyphicon-edit'
            callback: editCustomerCustomer
        ]
      ,
        head: 'Organization'
        name: 'organization'
        icon: 'group'
    ]

    new App.Sidebar(
      el:     @sidebar
      items:  items
    )

  render: ->
    @html App.view('layout_ref/content_sidebar_tabs_right')()

App.Config.set( 'layout_ref/content_sidebar_tabs_right', ContentSidebarTabsRight, 'Routes' )


class ContentSidebarLeft extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_left')()

App.Config.set( 'layout_ref/content_sidebar_left', ContentSidebarLeft, 'Routes' )


class ImportWizard extends App.ControllerContent
  elements:
    '[data-target]':  'links'
    '[data-slide]':   'slides'
    '[data-action]':  'actions'
    '#otrs-link':     'otrsLink'
    '.input-feedback':'inputFeedback'

  constructor: ->
    super
    @render()

    @links.on 'click', @navigate
    @actions.on 'click', @action

    # wait 500 ms after the last user input before we check the link
    @otrsLink.on 'input', _.debounce(@checkOtrsLink, 600) 

  checkOtrsLink: (e) =>
    if @otrsLink.val() is ""
      @inputFeedback.attr('data-state', '')
      return

    @inputFeedback.attr('data-state', 'loading')

    # send fake callback
    if @otrsLink.val() is '1337'
      state = 'success'
    else
      state = 'error'

    setTimeout @otrsLinkCallback, 1500, state

  otrsLinkCallback: (state) =>
    @inputFeedback.attr('data-state', state)

    @showNextButton @inputFeedback if state is 'success'

  action: (e) =>
    button = $(e.delegateTarget)

    switch button.attr('data-action')
      when "reveal" then @showNextButton button

  showNextButton: (sibling) ->
    sibling.parents('.wizard-slide').find('.btn.hide').removeClass('hide')

  navigate: (e) =>
    target = $(e.delegateTarget).attr('data-target')
    targetSlide = @$("[data-slide=#{ target }]")

    if targetSlide
      @goToSlide targetSlide

  goToSlide: (targetSlide) =>
    @slides.addClass('hide')
    targetSlide.removeClass('hide')

    if targetSlide.attr('data-hide')
      setTimeout @goToSlide, targetSlide.attr('data-hide'), targetSlide.next()


  render: ->
    @html App.view('layout_ref/import_wizard')()

App.Config.set( 'layout_ref/import_wizard', ImportWizard, 'Routes' )

App.Config.set( 'LayoutRef', { prio: 1700, parent: '#current_user', name: 'Layout Reference', target: '#layout_ref', role: [ 'Admin' ] }, 'NavBarRight' )
