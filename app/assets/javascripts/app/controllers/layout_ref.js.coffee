class Index extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/index')()

App.Config.set( 'layout_ref', Index, 'Routes' )


class Content extends App.ControllerContent
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganizationMembers'
    'click .js-organization':                 'showOrganizationMembers'
    'click .js-back':                         'hideOrganizationMembers'

  constructor: ->
    super
    @render()

    @dragEventCounter = 0
    @attachments = []

    for avatar in @$('.user.avatar')
      avatar = $(avatar)
      size = switch
        when avatar.hasClass('size-80') then 80
        when avatar.hasClass('size-50') then 50
        else 40
      @createUniqueAvatar avatar, size, avatar.data('firstname'), avatar.data('lastname'), avatar.data('userid')

  createUniqueAvatar: (holder, size, firstname, lastname, id) ->
    width = 300
    height = 226

    holder.addClass 'unique'

    rng = new Math.seedrandom(id)
    x = rng() * (width - size)
    y = rng() * (height - size)
    holder.css('background-position', "-#{ x }px -#{ y }px")

    holder.text(firstname[0] + lastname[0])

  render: ->
    @html App.view('layout_ref/content')()

  showOrganizationMembers: (e) =>
    e.stopPropagation()

    listEntry = $(e.currentTarget)
    organizationId = listEntry.data('organization-id')

    @recipientList = @$('.recipientList')
    @organizationList = @$("##{ organizationId }")

    # move organization-list to the right and slide it in

    $.Velocity.hook(@organizationList, 'translateX', '100%')
    @organizationList.removeClass('hide')

    @organizationList.velocity
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
        complete: => @recipientList.height(@organizationList.height())

  hideOrganizationMembers: (e) =>
    e && e.stopPropagation()

    return if !@organizationList

    # fade list back in

    @recipientList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # reset list height

    @recipientList.height('')

    # slide out organization-list and hide it
    @organizationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organizationList.addClass('hide')

App.Config.set( 'layout_ref/content', Content, 'Routes' )


class CommunicationOverview extends App.ControllerContent
  events:
    'click .js-unfold': 'unfold'

  constructor: ->
    super
    @render()

    @bindScrollPageHeader()

  bindScrollPageHeader: ->
    pageHeader = @$('.page-header')
    scrollHolder = pageHeader.scrollParent()
    scrollBody = scrollHolder.get(0).scrollHeight - scrollHolder.height()

  unfold: (e) ->
    container = $(e.currentTarget).parents('.textBubble-content')
    overflowContainer = container.find('.textBubble-overflowContainer')

    overflowContainer.velocity
      properties:
        opacity: 0
      options:
        duration: 300

    container.velocity
      properties:
        height: container.attr('data-height')
      options:
        duration: 300
        complete: -> overflowContainer.addClass('hide')

  render: ->
    @html App.view('layout_ref/communication_overview')()

    # set see more options
    previewHeight = 240
    @$('.textBubble-content').each( (index) ->
      bubble = $( @ )
      heigth = bubble.height()
      if heigth > (previewHeight + 30)
        bubble.attr('data-height', heigth)
        bubble.css('height', "#{previewHeight}px")
      else
        bubble.parent().find('.textBubble-overflowContainer').addClass('hide')
    )

App.Config.set( 'layout_ref/communication_overview', CommunicationOverview, 'Routes' )


class LayoutRefCommunicationReply extends App.ControllerContent
  elements:
    '.js-textarea' :                'textarea'
    '.attachmentPlaceholder':       'attachmentPlaceholder'
    '.attachmentPlaceholder-inputHolder': 'attachmentInputHolder'
    '.attachmentPlaceholder-hint':  'attachmentHint'
    '.article-new':                 'articleNewEdit'
    '.attachments':                 'attachmentsHolder'
    '.attachmentUpload':            'attachmentUpload'
    '.attachmentUpload-progressBar':'progressBar'
    '.js-percentage':               'progressText'
    '.textBubble':                 'textBubble'

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
      @content = "<p>some</p><p>multiline content</p>1<p>2</p><p>3</p>"

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
          complete: => @add_textarea_catcher()

      @textBubble.velocity
        properties:
          paddingBottom: 28
        options:
          duration: duration
          easing: 'easeOutQuad'

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
      holder: @articleNewEdit.offsetParent()
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

      # @editControlItem.css('display', 'none')

  onDragenter: (event) =>
    # on the first event,
    # open textarea (it will only open if its closed)
    @open_textarea() if @dragEventCounter is 0

    @dragEventCounter++
    @articleNewEdit.addClass('is-dropTarget')

  onDragleave: (event) =>
    @dragEventCounter--

    @articleNewEdit.removeClass('is-dropTarget') if @dragEventCounter is 0

  onFileDrop: (event) =>
    event.preventDefault()
    event.stopPropagation()
    files = event.originalEvent.dataTransfer.files
    @articleNewEdit.removeClass('is-dropTarget')

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

    progress = 0
    duration = fileSize / 1024

    for i in [0..100]
      setTimeout @updateUploadProgress, i*duration/100 , i

    setTimeout (=> 
      callback()
      @renderAttachment(fileName, fileSize)
    ), duration

  renderAttachment: (fileName, fileSize) =>
    @attachments.push([fileName, fileSize])
    @attachmentsHolder.append App.view('generic/attachment_item')
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
    @content = controller.form

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
    @show( App.view('layout_ref/content')() )

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
            title:    'Change Customer'
            name:     'change-customer'
            callback: changeCustomerTicket
          ,
            title:    'Edit Customer'
            name:     'edit-customer'
            callback: editCustomerTicket
        ]
      ,
        head: 'Customer'
        name: 'customer'
        icon: 'person'
        callback: (el) ->
          el.html('some customer')
        actions: [
            title:    'Change Customer'
            name:     'change-customer'
            callback: changeCustomerCustomer
          ,
            title:    'Edit Customer'
            name:     'edit-customer'
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


class App.ControllerWizard extends App.ControllerContent
  elements:
    '[data-slide]':   'slides'

  events:
    'click [data-target]': 'navigate'
    'click [data-action]': 'action'

  constructor: ->
    super

  action: (e) =>
    button = $(e.currentTarget)

    switch button.attr('data-action')
      when "reveal" then @showNextButton button

  showNextButton: (sibling) ->
    sibling.parents('.wizard-slide').find('.btn.hide').removeClass('hide')

  navigate: (e) =>
    target = $(e.currentTarget).attr('data-target')
    targetSlide = @$("[data-slide=#{ target }]")
    console.log(e, target, targetSlide)

    if targetSlide
      @goToSlide targetSlide

  goToSlide: (targetSlide) =>
    @slides.addClass('hide')
    targetSlide.removeClass('hide')

    if targetSlide.attr('data-hide')
      setTimeout @goToSlide, targetSlide.attr('data-hide'), targetSlide.next()


class ImportWizard extends App.ControllerWizard
  elements:
    '#otrs-link':     'otrsLink'
    '.input-feedback':'inputFeedback'

  constructor: ->
    super
    @render()

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

  render: ->
    @html App.view('layout_ref/import_wizard')()

App.Config.set( 'layout_ref/import_wizard', ImportWizard, 'Routes' )

class ReferenceUserProfile extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/user_profile')()

App.Config.set( 'layout_ref/user_profile', ReferenceUserProfile, 'Routes' )

class ReferenceOrganizationProfile extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/organization_profile')()

App.Config.set( 'layout_ref/organization_profile', ReferenceOrganizationProfile, 'Routes' )

class ReferenceSetupWizard extends App.ControllerWizard
  elements:
    '.logo-preview': 'logoPreview'
    '#agent_email': 'agentEmail'
    '#agent_first_name': 'agentFirstName'
    '#agent_last_name': 'agentLastName'

  events:
    'change .js-upload': 'onLogoPick'
    'click .js-inviteAgent': 'inviteAgent'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/setup')()

  onLogoPick: (event) =>
    reader = new FileReader()

    reader.onload = (e) =>
      @logoPreview.attr('src', e.target.result)

    reader.readAsDataURL(event.target.files[0])

  inviteAgent: =>
    firstname = @agentFirstName.val()
    lastname = @agentLastName.val()

    App.Event.trigger 'notify', {
      type:    'success'
      msg:     App.i18n.translateContent( "Invitation sent to #{ firstname } #{ lastname }" )
      timeout: 3500
    }

    @agentEmail.add(@agentFirstName).add(@agentLastName).val('')
    @agentFirstName.focus()

App.Config.set( 'layout_ref/setup', ReferenceSetupWizard, 'Routes' )

class RichText extends App.ControllerContent
  constructor: ->
    super
    @render()

    @$('.js-text-oneline').ce({
      mode:      'textonly'
      multiline: false
      maxlength: 250
    })

    @$('.js-text-multiline').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

    @$('.js-text-richtext').ce({
      mode:      'richtext'
      multiline: true
      maxlength: 250
    })
    return

    @$('.js-textarea').on('keyup', (e) =>
      console.log('KU')
      textarea = @$('.js-textarea')
      App.Utils.htmlCleanup(textarea)
    )

    @$('.js-textarea').on('paste', (e) =>
      console.log('paste')
      #console.log('PPP', e, e.originalEvent.clipboardData)

      execute = =>

        # add marker for cursor
        getFirstRange = ->
          sel = rangy.getSelection()
          if sel.rangeCount
            sel.getRangeAt(0)
          else
            null
        range = getFirstRange()
        if range
          el = document.createElement('span')
          $(el).attr('data-cursor', 1)
          range.insertNode(el)
          rangy.getSelection().setSingleRange(range)

        # cleanup
        textarea = @$('.js-textarea')
        App.Utils.htmlCleanup(textarea)

        # remove marker for cursor
        textarea.find('[data-cursor=1]').focus()
        textarea.find('[data-cursor=1]').remove()
      @delay( execute, 1)

      return
    )
    #editable.style.borderColor = '#54c8eb'
    #aloha(editable)
    return

  render: ->
    @html App.view('layout_ref/richtext')()

App.Config.set( 'layout_ref/richtext', RichText, 'Routes' )

class LocalModalRef extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/local_modal')()

App.Config.set( 'layout_ref/local_modal', LocalModalRef, 'Routes' )

class loadingPlaceholderRef extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/loading_placeholder')()

App.Config.set( 'layout_ref/loading_placeholder', loadingPlaceholderRef, 'Routes' )

class insufficientRightsRef extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/insufficient_rights')()

App.Config.set( 'layout_ref/insufficient_rights', insufficientRightsRef, 'Routes' )


class errorRef extends App.ControllerContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/error')()

App.Config.set( 'layout_ref/error', errorRef, 'Routes' )


class highlightRef extends App.ControllerContent
  elements:
    '.article-text': 'articles'
    '.js-highlight-icon': 'highlightIcon'

  events:
    'click .js-highlight': 'toggleHighlight'
    'click .js-highlightColor': 'pickColor'

  colors: [
    {
      name: 'Yellow'
      color: "#f7e7b2"
    },
    {
      name: 'Green'
      color: "#bce7b6"
    },
    {
      name: 'Blue'
      color: "#b3ddf9"
    },
    {
      name: 'Pink'
      color: "#fea9c5"
    },
    {
      name: 'Purple'
      color: "#eac5ee"
    }
  ]

  activeColorIndex: 0
  highlightClassPrefix: "highlight-"

  constructor: ->
    super
    rangy.init()

    @highlighter = rangy.createHighlighter(document, 'TextRange')

    @addClassApplier entry for entry in @colors

    @setColor()
    @render()

    @loadHighlights()

  render: ->
    @html App.view('layout_ref/highlight')
      colors: @colors
      activeColorIndex: @activeColorIndex

  # for testing purposes the highlights get stored in localStorage
  loadHighlights: ->
    if highlights = localStorage['highlights']
      @highlighter.deserialize localStorage['highlights']

  # the serialization creates one string for the entiery ticket
  # containing the offsets and the highlight classes
  #
  # we have to check how it works with having open several tickets – it might break
  # 
  # if classes can be changed in the admin interface
  # we have to watch out to not end up with empty highlight classes
  storeHighlights: ->
    localStorage['highlights'] = @highlighter.serialize()

  # the colors is set via css classes (can't do it inline with rangy)
  # thus we have to create a stylesheet if the colors 
  # can be changed in the admin interface
  addClassApplier: (entry) ->
    @highlighter.addClassApplier rangy.createCssClassApplier(@highlightClassPrefix + entry.name)

  setColor: ->
    @highlightClass = @highlightClassPrefix + @colors[@activeColorIndex].name

    if @isActive
      @articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

  toggleHighlight: (e) =>
    if @isActive
      @highlightIcon.css('fill', '')
      @isActive = false
      @articles.off('mouseup', @onMouseUp)
      @articles.removeAttr('data-highlightcolor')
    else
      selection = rangy.getSelection()
      # if there's already something selected, 
      # don't go into highlight mode
      # just toggle the selected
      if !selection.isCollapsed
        @toggleHighlightAtSelection $(selection.anchorNode).closest @articles.selector
      else
        # show color
        @highlightIcon.css('fill', @colors[@activeColorIndex].color)

        # activate selection background
        @articles.attr('data-highlightcolor', @colors[@activeColorIndex].name)

        @isActive = true
        @articles.on('mouseup', @onMouseUp) #future: touchend

  pickColor: (e) =>
    @$('.js-highlightColor .visibility-change.is-active').removeClass('is-active')
    $(e.currentTarget).find('.visibility-change').addClass('is-active')
    @activeColorIndex =  $(e.currentTarget).attr('data-key')

    if @isActive
      @highlightIcon.css('fill', @colors[@activeColorIndex].color)

    @setColor() 

  onMouseUp: (e) =>
    @toggleHighlightAtSelection $(e.currentTarget).closest @articles.selector

  # 
  # toggle Highlight
  # ================
  # 
  # - only works when the selection starts and ends inside an article
  # - clears highlights in selection
  # - or highlights the selection
  # - clears the selection

  toggleHighlightAtSelection: (article) ->
    selection = rangy.getSelection()

    if @highlighter.selectionOverlapsHighlight selection
      @highlighter.unhighlightSelection()
    else
      @highlighter.highlightSelection @highlightClass,
        selection: selection
        containerElementId: article.get(0).id    

      # remove selection
      selection.removeAllRanges()

    @storeHighlights()


App.Config.set( 'layout_ref/highlight', highlightRef, 'Routes' )


class cluesRef extends App.ControllerContent

  clues: [
    {
      container: '.search'
      headline: 'Suche'
      text: 'Hier finden sie alles!'
    },
    {
      container: '.user-menu'
      headline: 'Erstellen'
      text: 'Hier können sie Tickets, Kunden und Organisationen anlegen.'
      action: 'click .add .js-action'
    }
  ]

  events:
    'click .js-next': 'next'
    'click .js-previous': 'previous'

  constructor: ->
    super

    ###

    options
      clues: list of clues
      onComplete: a callback for when the user is done

    ###

    @options.onComplete = ->
    @position = 0
    @render()

  next: (event) =>
    event.stopPropagation()
    @navigate 1

  previous: (event) =>
    event.stopPropagation()
    @navigate -1

  navigate: (direction) ->
    @cleanUp()
    @position += direction

    if @position < @clues.length
      @render()
    else
      @onComplete()

  cleanUp: ->
    clue = @clues[@position]
    container = $(clue.container)
    container.removeClass('selected-clue')

    # undo click perform by doing it again
    if clue.action
      @perform clue.action, container

    @el.find('.clue').remove()

  render: ->
    clue = @clues[@position]
    container = $(clue.container)
    container.addClass('selected-clue')

    center =
      x: container.offset().left + container.width()/2
      y: container.offset().top + container.height()/2

    @html App.view('layout_ref/clues')
      headline: clue.headline
      text: clue.text
      width: container.outerWidth()
      height: container.outerHeight()
      center: center
      position: @position
      max: @clues.length

    if clue.action
      @perform clue.action, container

    @placeWindow(container)

  placeWindow: (container) ->
    clueWindow = @el.find('.clue-window')

    # see if we can place it above or below target
    if clueWindow.outerHeight() + container.outerHeight() < $(window).outerHeight()
      clueWindow.css('left', container.offset().left)

      # below or above ?
      if container.offset().top + container.outerHeight() + clueWindow.outerHeight() < $(window).outerHeight()
        # place below
        clueWindow.css('top', container.offset().top + container.outerHeight())
      else
        # place above
        clueWindow.css('top', container.offset().top - container.outerHeight() - clueWindow.outerHeight())
    else
      clueWindow.css('top', container.offset().top)
      # okay, let's try right or left then
      if container.offset().left + container.outerWidth() + clueWindow.outerWidth() < $(window).outerWidth()
        # place right
        clueWindow.css('left', container.offset().left + container.outerWidth())
      else
        # place left
        clueWindow.css('left', container.offset().left - container.outerWidth() - clueWindow.outerWidth())

    # show window
    clueWindow.addClass('is-visible')


  perform: (action, container) ->
    eventName = action.substr 0, action.indexOf(' ')
    selector = action.substr action.indexOf(' ') + 1
    container.find(selector)[0][eventName]()

App.Config.set( 'layout_ref/clues', cluesRef, 'Routes' )



App.Config.set( 'LayoutRef', { prio: 1700, parent: '#current_user', name: 'Layout Reference', translate: true, target: '#layout_ref', role: [ 'Admin' ] }, 'NavBarRight' )