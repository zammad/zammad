class LayoutRef extends App.ControllerAppContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/index')()

App.Config.set('layout_ref', LayoutRef, 'Routes')


class Content extends App.ControllerAppContent
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

    holder.addClass 'avatar--unique'

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


class CommunicationOverview extends App.ControllerAppContent
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


class LayoutRefCommunicationReply extends App.ControllerAppContent
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
      @content = 'some content la la la la'
    else
      @content = '<p>some</p><p>multiline content</p>1<p>2</p><p>3</p>'

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

  release: =>
    @remove_textarea_catcher()

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
          translateX: -@attachmentInputHolder.position().left + 'px'
        options:
          duration: duration
          easing: 'easeOutQuad'

      @attachmentHint.velocity
        properties:
          opacity: 0
        options:
          duration: duration

  add_textarea_catcher: ->
    $(window).on 'click.LayoutRefCommunicationReply-textarea', @close_textarea

  remove_textarea_catcher: ->
    $(window).off 'click.LayoutRefCommunicationReply-textarea'

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
    @fakeUpload(file.name, file.size, @workOfUploadQueue)

  humanFileSize: (size) ->
    i = Math.floor( Math.log(size) / Math.log(1024) )
    return ( size / Math.pow(1024, i) ).toFixed(2) * 1 + ' ' + ['B', 'kB', 'MB', 'GB', 'TB'][i]

  updateUploadProgress: (progress) =>
    @progressBar.width(progress + '%')
    @progressText.text(progress)

    if progress is 100
      @attachmentPlaceholder.removeClass('hide')
      @attachmentUpload.addClass('hide')

  fakeUpload: (filename, size, callback) ->
    @attachmentPlaceholder.addClass('hide')
    @attachmentUpload.removeClass('hide')

    progress = 0
    duration = size / 1024

    for i in [0..100]
      setTimeout @updateUploadProgress, i*duration/100 , i

    setTimeout (=>
      callback()
      @renderAttachment(filename, size)
    ), duration

  renderAttachment: (filename, size) =>
    @attachments.push([filename, size])
    @attachmentsHolder.append(App.view('generic/attachment_item')
      filename: filename
      size: @humanFileSize(size)
    )

App.Config.set( 'layout_ref/communication_reply/:content', LayoutRefCommunicationReply, 'Routes' )



class ContentSidebarRight extends App.ControllerAppContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right')()

App.Config.set( 'layout_ref/content_sidebar_right', ContentSidebarRight, 'Routes' )


class ContentSidebarRightSidebarOptional extends App.ControllerAppContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_right_sidebar_optional')()

App.Config.set( 'layout_ref/content_sidebar_right_sidebar_optional', ContentSidebarRightSidebarOptional, 'Routes' )


class ModalForm extends App.ControllerModal
  head: '123 some title'

  content: ->
    controller = new App.ControllerForm(
      model: App.User
      autofocus: true
    )
    controller.form

  onHide: ->
    window.history.back()

  onSubmit: (e) ->
    e.preventDefault()
    params = App.ControllerForm.params( $(e.target).closest('form') )

App.Config.set( 'layout_ref/modal_form', ModalForm, 'Routes' )


class ModalText extends App.ControllerModal

  content: ->
    App.view('layout_ref/content')()

  onHide: ->
    window.history.back()

App.Config.set( 'layout_ref/modal_text', ModalText, 'Routes' )


class ContentSidebarTabsRight extends App.ControllerAppContent
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


class ContentSidebarLeft extends App.ControllerAppContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content_sidebar_left')()

App.Config.set( 'layout_ref/content_sidebar_left', ContentSidebarLeft, 'Routes' )


class App.ControllerWizard extends App.ControllerAppContent
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
      when 'reveal' then @showNextButton button

  showNextButton: (sibling) ->
    sibling.parents('.wizard-slide').find('.btn.hide').removeClass('hide')

  navigate: (e) =>
    target = $(e.currentTarget).attr('data-target')
    targetSlide = @$("[data-slide=#{ target }]")

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
    if @otrsLink.val() is ''
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

class ReferenceUserProfile extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/user_profile')()

App.Config.set( 'layout_ref/user_profile', ReferenceUserProfile, 'Routes' )

class ReferenceOrganizationProfile extends App.ControllerAppContent

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

class RichText extends App.ControllerAppContent
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
      textarea = @$('.js-textarea')
      App.Utils.htmlCleanup(textarea)
    )

    @$('.js-textarea').on('paste', (e) =>
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

class LocalModalRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/local_modal')()

App.Config.set( 'layout_ref/local_modal', LocalModalRef, 'Routes' )

class LoadingPlaceholderRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/loading_placeholder')()

App.Config.set( 'layout_ref/loading_placeholder', LoadingPlaceholderRef, 'Routes' )

class InsufficientRightsRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/insufficient_rights')()

App.Config.set( 'layout_ref/insufficient_rights', InsufficientRightsRef, 'Routes' )


class ErrorRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/error')()

App.Config.set( 'layout_ref/error', ErrorRef, 'Routes' )


class TicketZoomRef extends App.ControllerAppContent
  elements:
    '.article-text': 'articles'
    '.js-highlight-icon': 'highlightIcon'

    '.js-submitDropdown': 'buttonDropdown'

  events:
    'click .js-highlight': 'toggleHighlight'
    'click .js-highlightColor': 'pickColor'

    'mousedown .js-openDropdown': 'toggleDropdown'
    'click .js-openDropdown': 'stopPropagation'
    'mouseup .js-dropdownAction': 'performTicketMacro'
    'mouseenter .js-dropdownAction': 'onActionMouseEnter'
    'mouseleave .js-dropdownAction': 'onActionMouseLeave'
    'click .js-secondaryAction': 'chooseSecondaryAction'

  stopPropagation: (event) ->
    event.stopPropagation()

  colors: [
    {
      name: 'Yellow'
      color: '#f7e7b2'
    },
    {
      name: 'Green'
      color: '#bce7b6'
    },
    {
      name: 'Blue'
      color: '#b3ddf9'
    },
    {
      name: 'Pink'
      color: '#fea9c5'
    },
    {
      name: 'Purple'
      color: '#eac5ee'
    }
  ]

  activeColorIndex: 0
  highlightClassPrefix: 'highlight-'

  constructor: ->
    super
    rangy.init()

    @highlighter = rangy.createHighlighter(document, 'TextRange')

    @addClassApplier entry for entry in @colors

    @setColor()
    @render()

    @loadHighlights()

  render: ->
    @html App.view('layout_ref/ticket_zoom')
      colors: @colors
      activeColorIndex: @activeColorIndex

    @$('.js-datepicker').datepicker
      todayHighlight: true
      startDate: new Date().toLocaleDateString('en-US') # returns 9/25/2015
      container: @$('.js-datepicker').parent()

    @$('.js-timepicker').timepicker()

  # for testing purposes the highlights get stored in localStorage
  loadHighlights: ->
    if highlights = localStorage['highlights']
      @highlighter.deserialize localStorage['highlights']

  # the serialization creates one string for the entire ticket
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
      @deactivate()
    else
      @activate()

  deactivate: ->
    @highlightIcon.css('fill', '')
    @isActive = false
    @articles.off('mouseup', @onMouseUp)
    @articles.removeAttr('data-highlightcolor')

  activate: ->
    selection = rangy.getSelection()
    # if there's already something selected,
    # don't go into highlight mode
    # just toggle the selected
    if !selection.isCollapsed
      @toggleHighlightAtSelection selection, $(selection.anchorNode).closest @articles.selector
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
    @activeColorIndex = $(e.currentTarget).attr('data-key')

    if not @isActive
      @activate()
    else
      @highlightIcon.css('fill', @colors[@activeColorIndex].color)

    @setColor()

  onMouseUp: (e) =>
    selection = rangy.getSelection()

    @toggleHighlightAtSelection selection, $(e.currentTarget).closest @articles.selector

  #
  # toggle Highlight
  # ================
  #
  # - only works when the selection starts and ends inside an article
  # - clears highlights in selection
  # - or highlights the selection
  # - clears the selection

  toggleHighlightAtSelection: (selection, article) ->

    if @highlighter.selectionOverlapsHighlight selection
      @highlighter.unhighlightSelection()
      return @storeHighlights()

    # selection.anchorNode = element in which the selection started
    # selection.focusNode = element in which the selection ended
    #
    # check if the start node is inside of the article or the article itself
    startNode = @$(selection.anchorNode)

    if !(article.is(startNode) or article.contents().is(startNode))
      return selection.removeAllRanges()

    @highlighter.highlightSelection @highlightClass,
      selection: selection
      containerElementId: article.get(0).id

    # remove selection
    selection.removeAllRanges()

    @storeHighlights()

  toggleDropdown: =>
    if @buttonDropdown.hasClass 'is-open'
      @closeDropdown()
    else
      @buttonDropdown.addClass 'is-open'
      $(document).bind 'click.buttonDropdown', @closeDropdown

  closeDropdown: =>
    @buttonDropdown.removeClass 'is-open'
    $(document).unbind 'click.buttonDropdown'

  performTicketMacro: (event) =>
    console.log 'perform action', @$(event.currentTarget).text()
    @closeDropdown()

  onActionMouseEnter: (event) =>
    @$(event.currentTarget).addClass('is-active')

  onActionMouseLeave: (event) =>
    @$(event.currentTarget).removeClass('is-active')

  chooseSecondaryAction: (event) =>
    target = $(event.currentTarget)
    target.siblings().find('.is-selected').removeClass('is-selected')
    @$('.js-secondaryActionButtonLabel').text target.find('.js-secondaryActionLabel').text()
    target.find('.js-selectedIcon').addClass('is-selected')



App.Config.set( 'layout_ref/ticket_zoom', TicketZoomRef, 'Routes' )


class CluesRef extends App.ControllerAppContent

  clues: [
    {
      container: '.search-holder'
      headline: 'Suche'
      text: 'Um alles zu finden nutze den <kbd>*</kbd>-Platzhalter'
    }
    {
      container: '.user-menu'
      headline: 'Erstellen'
      text: 'Hier kannst du Tickets, Kunden und Organisationen anlegen.'
      actions: [
        'click .add .js-action',
        'hover .add'
      ]
    }
    {
      container: '.user-menu'
      headline: 'Persönliches Menü'
      text: 'Hier findest du den Logout, den Weg zu deinen Einstellungen und deinen Verlauf.'
      actions: [
        'click .user .js-action',
        'hover .user'
      ]
    }
    {
      container: '.js-overviewsMenuItem'
      headline: 'Übersichten'
      text: 'Hier findest du eine Liste aller Tickets.'
      actions: [
        'hover'
      ]
    }
    {
      container: '.js-dashboardMenuItem'
      headline: 'Dashboard'
      text: 'Hier siehst du auf einem Blick ob sich alle Agenten an die Spielregeln halten.'
      actions: [
        'hover'
      ]
    }
  ]

  elements:
    '.js-positionOrigin': 'modalWindow'
    '.js-backdrop':       'backdrop'

  events:
    'click': 'stopPropagation'
    'click .js-next': 'next'
    'click .js-previous': 'previous'
    'click .js-close': 'close'

  constructor: ->
    super

    ###

    options
      clues: list of clues
      onComplete: a callback for when the user is done

    ###

    @options.onComplete = -> null
    @position = 0
    @render()

  stopPropagation: (event) ->
    event.stopPropagation()

  next: (event) =>
    event.stopPropagation()
    @navigate 1

  previous: (event) =>
    event.stopPropagation()
    @navigate -1

  close: =>
    @cleanUp()
    @options.onComplete()
    @remove()

  remove: ->
    @$('.modal').remove()

  navigate: (direction) ->
    @cleanUp =>
      @position += direction

      if @position < @clues.length
        @showClue()
      else
        @options.onComplete()
        @remove()

  cleanUp: (callback) ->
    @hideWindow =>
      clue = @clues[@position]
      container = $(clue.container)
      container.removeClass('selected-clue')

      # undo click perform by doing it again
      if clue.actions
        @perform clue.actions, container

      callback()

  render: ->
    @html App.view('layout_ref/clues')
    @backdrop.velocity
      properties:
        opacity: [1, 0]
      options:
        duration: 300
        complete: @showClue

  showClue: =>
    clue = @clues[@position]
    container = $(clue.container)
    container.addClass('selected-clue')

    if clue.actions
      @perform clue.actions, container

    # calculate bounding box after actions
    # to take toggled child nodes into account
    boundingBox = @getVisibleBoundingBox(container.get(0))

    center =
      x: boundingBox.left + boundingBox.width/2
      y: boundingBox.top + boundingBox.height/2

    @modalWindow.html App.view('layout_ref/clue_content')
      headline: clue.headline
      text: clue.text
      position: @position
      max: @clues.length

    @placeWindow(boundingBox)

    @backdrop.velocity
      properties:
        translateX: center.x
        translateY: center.y
        translateZ: 0
      options:
        duration: 300
        complete: @showWindow

  showWindow: =>
    @modalWindow.velocity
      properties:
        scale: [1, 0.2]
        opacity: [1, 0]
      options:
        duration: 300
        easing: [0.34,1.61,0.7,1]

  hideWindow: (callback) =>
    @modalWindow.velocity
      properties:
        scale: [0.2, 1]
        opacity: 0
      options:
        duration: 200
        complete: callback


  placeWindow: (target) ->
    # reset scale in order to get correct measurements
    $.Velocity.hook(@modalWindow, 'scale', 1)

    modal = @modalWindow.get(0).getBoundingClientRect()
    position = ''
    left = 0
    top = 0
    maxWidth = $(window).width()
    maxHeight = $(window).height()

    # try to place it parallel to the larger side
    if target.height > target.width
      # try to place it aside
      # prefer right
      if target.right + modal.width <= maxWidth
        left = target.right
        position = 'right'
      else
        # place left
        left = target.left - modal.width
        position = 'left'

      if position
        top = target.top + target.height/2 - modal.height/2
    else if target.height <= target.width or !position
      # try to place it above or below
      # prefer above
      if target.top - modal.height >= 0
        top = target.top - modal.height
        position = 'above'
      else
        top = target.bottom
        position = 'below'

      if position
        left = target.left + target.width/2 - modal.width/2

    # keep it inside the window
    # horizontal
    if left < 0
      moveArrow = modal.width/2 + left
      left = 0
    else if left + modal.width > maxWidth
      moveArrow = modal.width/2 + maxWidth - (left + modal.width)
      left = maxWidth - modal.width

    if top < 0
      moveArrow = modal.height/2 + height
      top = 0
    else if top + modal.height > maxHeight
      moveArrow = modal.height/2 + maxHeight - (top + modal.height)
      top = maxHeight - modal.height

    transformOrigin = @getTransformOrigin(modal, position)

    if moveArrow
      parameter = if position is 'above' or position is 'below' then 'left' else 'top'
      # move arrow
      @modalWindow.find('.js-arrow').css(parameter, moveArrow)

      # adjust transform origin
      if position is 'above' or position is 'below'
        transformOrigin.x = moveArrow
      else
        transformOrigin.y = moveArrow

    # place window
    @modalWindow
      .attr 'data-position', position
      .css
        left: left
        top: top
        transformOrigin: "#{transformOrigin.x}px #{transformOrigin.y}px"

  getTransformOrigin: (modal, position) ->
    positionDictionary =
      above:
        x: modal.width/2
        y: modal.height
      below:
        x: modal.width/2
        y: 0
      left:
        x: modal.width + @transformOriginPadding
        y: modal.height/2
      right:
        x: -@transformOriginPadding
        y: modal.height/2

    return positionDictionary[position]

  getVisibleBoundingBox: (el) ->
    ###

      getBoundingClientRect doesn't take
      absolute-positioned child nodes into account

    ###
    children = el.querySelectorAll('*')
    bb = el.getBoundingClientRect()
    dimensions =
      left: bb.left,
      right: bb.right,
      top: bb.top,
      bottom: bb.bottom

    for child in children

      continue if getComputedStyle(child).position is not 'absolute'

      bb = child.getBoundingClientRect()

      continue if bb.width is 0 or bb.height is 0

      if bb.left < dimensions.left
        dimensions.left = bb.left
      if bb.top < dimensions.top
        dimensions.top = bb.top
      if bb.right > dimensions.right
        dimensions.right = bb.right
      if bb.bottom > dimensions.bottom
        dimensions.bottom = bb.bottom

    dimensions.width = dimensions.right - dimensions.left
    dimensions.height = dimensions.bottom - dimensions.top

    dimensions

  perform: (actions, container) ->
    for action in actions
      if action.indexOf(' ') < 0
        # 'click'
        eventName = action
        target = container
      else
        # 'click .target'
        eventName = action.substr 0, action.indexOf(' ')
        target = container.find( action.substr action.indexOf(' ') + 1 )

      switch eventName
        when 'click' then target.trigger('click')
        when 'hover' then target.toggleClass('is-hovered')

App.Config.set( 'layout_ref/clues', CluesRef, 'Routes' )


class AdminPlaceholderRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/admin_placeholder')()

App.Config.set( 'layout_ref/admin_placeholder', AdminPlaceholderRef, 'Routes' )

class UserListRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/user_list')()

App.Config.set( 'layout_ref/user_list', UserListRef, 'Routes' )


class SlaRef extends App.ControllerAppContent

  events:
    'click .js-activateColumn': 'activateColumn'
    'click .js-activateRow': 'activateRow'
    'click [data-type=new]': 'createNew'
    'click .js-toggle': 'toggle'
    'change .js-selectTimezone': 'selectTimezone'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/sla')()
    @createNew()

  selectTimezone: (e) =>
    @$('.js-timezone').text e.currentTarget.value

  toggle: (e) ->
    entry = $(e.currentTarget).closest('.action')
    isInactive = entry.hasClass('is-inactive')
    entry.toggleClass('is-inactive')
    isInactive = !isInactive
    entry.find('.js-toggle')
      .toggleClass('btn--danger btn--secondary')
      .text(if isInactive then 'Enable' else 'Disable')

  activateColumn: (event) =>
    checkbox = @$(event.currentTarget)
    columnName = checkbox.attr('data-target')
    @$("[data-column=#{columnName}]").toggleClass('is-active', checkbox.prop('checked'))

  activateRow: (event) =>
    checkbox = @$(event.currentTarget)
    checkbox.closest('tr').toggleClass('is-active', checkbox.prop('checked'))

  createNew: =>
    @newItemModal = new App.ControllerModal
      head: 'Service Level Agreement (SLA)'
      headPrefox: 'New'
      contentInline: App.view('layout_ref/sla_modal')()
      buttonSubmit: 'Create SLA'
      shown: true
      buttonCancel: true
      container: @el
      onShown: =>
        @$('.js-responseTime').timepicker
          maxHours: 99
        @$('.js-time').timepicker
          showMeridian: true # meridian = am/pm

App.Config.set( 'layout_ref/sla', SlaRef, 'Routes' )


class SchedulersRef extends App.ControllerAppContent
  events:
    'click .select-value': 'select'
    'click [data-type=new]': 'createNew'
    'click .js-toggle': 'toggle'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/schedulers')()

  toggle: (e) ->
    entry = $(e.currentTarget).closest('.action')
    isInactive = entry.hasClass('is-inactive')
    entry.toggleClass('is-inactive')
    isInactive = !isInactive
    entry.find('.js-toggle')
      .toggleClass('btn--danger btn--secondary')
      .text(if isInactive then 'Enable' else 'Disable')

  createNew: =>
    new App.ControllerModal
      head: 'Scheduler'
      headPrefix: 'New'
      buttonSubmit: 'Create'
      buttonCancel: true
      contentInline: App.view('layout_ref/scheduler_modal')()
      shown: true
      container: @el

  select: (event) =>
    target = $(event.currentTarget)

    if target.hasClass('is-selected')
      # prevent zero selections
      if target.siblings('.is-selected').size() > 0
        target.removeClass('is-selected')
    else
      target.addClass('is-selected')

    @createOutputString()

  createOutputString: ->
    days = $.map(@$('[data-type=day]').filter('.is-selected'), (el) -> return $(el).text() )
    hours = $.map(@$('[data-type=hour]').filter('.is-selected'), (el) -> return $(el).text() )
    minutes = $.map(@$('[data-type=minute]').filter('.is-selected'), (el) -> return $(el).text() )

    hours = @injectMinutes(hours, minutes)

    days = @joinItems days
    hours = @joinItems hours

    @$('.js-timerResult').text("Run every #{ days } at #{ hours }")

  injectMinutes: (hours, minutes) ->
    newHours = [] # hours.length x minutes.length long

    for hour in hours
      # split off am/pm
      [hour, suffix] = hour.split(' ')

      for minute in minutes
        combined = "#{ hour }:#{ minute }"
        combined += " #{suffix}" if suffix

        newHours.push combined

    return newHours

  joinItems: (items) ->
    switch items.length
      when 1 then return items[0]
      when 2 then return "#{ items[0] } and #{ items[1] }"
      else
        return "#{ items.slice(0, -1).join(', ') } and #{ items[items.length-1] }"

App.Config.set( 'layout_ref/schedulers', SchedulersRef, 'Routes' )

class InputsRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/inputs')()

    # activate widgets

    # selectable search
    searchableSelectObject = new App.SearchableSelect
      attribute:
        name:        'project-name'
        id:          'project-name-123'
        placeholder: 'Enter Project Name'
        options:     [{value:0,name:'Apple',selected:true},
        {value:1,name:'Microsoft',selected:true},
        {value:2,name:'Google'},
        {value:3,name:'Deutsche Bahn'},
        {value:4,name:'Sparkasse'},
        {value:5,name:'Deutsche Post'},
        {value:6,name:'Mitfahrzentrale'},
        {value:7,name:'Starbucks'},
        {value:8,name:'Mac Donalds'},
        {value:9,name:'Flixbus'},
        {value:10,name:'Betahaus'},
        {value:11,name:'Bruno Banani'},
        {value:12,name:'Alpina'},
        {value:13,name:'Samsung'},
        {value:14,name:'ChariTea'},
        {value:15,name:'fritz-kola'},
        {value:16,name:'Vitamin Water'},
        {value:17,name:'Znuny'},
        {value:18,name:'Max & Moritz'}]
    @$('.searchableSelectPlaceholder').replaceWith( searchableSelectObject.element() )

    # selectable search
    searchableAjaxSelectObject = new App.SearchableAjaxSelect
      attribute:
        name:        'user'
        id:          'user-123'
        placeholder: 'Enter User'
        limt:        10
        object:      'User'

    @$('.searchableAjaxSelectPlaceholder').replaceWith( searchableAjaxSelectObject.element() )

    # user organization autocomplete
    userOrganizationAutocomplete = new App.UserOrganizationAutocompletion
      attribute:
        name: 'customer_id'
        display: 'Customer'
        tag: 'user_autocompletion'
        type: 'text'
        limit: 200
        null: false
        relation: 'User'
        autocapitalize: false
        disableCreateObject: true
        multiple: true

    @$('.userOrganizationAutocompletePlaceholder').replaceWith( userOrganizationAutocomplete.element() )

    # time and timeframe
    @$('.js-timepicker1, .js-timepicker2').timepicker()

    @$('.timeframe').timepicker(
      maxHours: 99
    )

    # date picker
    @$('.js-datepicker3').datepicker(
      todayHighlight: true
      startDate: new Date()
      format: App.i18n.timeFormat().date
      rtl: App.i18n.dir() is 'rtl'
      container: @$('.js-datepicker3').parent()
    )

    # date time picker
    @$('.js-datepicker4').datepicker(
      todayHighlight: true
      startDate: new Date()
      format: App.i18n.timeFormat().date
      rtl: App.i18n.dir() is 'rtl'
      container: @$('.js-datepicker4').parent()
    )
    @$('.js-timepicker4').timepicker()

    # column select
    columnSelectObject = new App.ColumnSelect
      attribute:
        name:        'company-name'
        id:          'company-name-12345'
        options:     [
          {label:'Group A', group: [
            {value:0,name:'Apple'},
            {value:1,name:'Microsoft',selected:true},
            {value:2,name:'Google'},
            {value:3,name:'Deutsche Bahn'},
            {value:4,name:'Sparkasse'},
            {value:5,name:'Deutsche Post'},
            {value:6,name:'Mitfahrzentrale'}
          ]},
          {label:'Group B', group: [
            {value:7,name:'Starbucks'},
            {value:8,name:'Mac Donalds'},
            {value:9,name:'Flixbus'},
            {value:10,name:'Betahaus'},
            {value:11,name:'Bruno Banani'},
            {value:12,name:'Alpina'},
            {value:13,name:'Samsung'},
            {value:14,name:'ChariTea'},
            {value:15,name:'fritz-kola'},
            {value:16,name:'Vitamin Water'},
            {value:17,name:'Znuny'},
            {value:18,name:'Max & Moritz'},
            {value:19,name:'Telefónica Deutschland Holding GmbH'}
          ]}
        ]
    @$('.columnSelectPlaceholder').replaceWith( columnSelectObject.element() )

App.Config.set( 'layout_ref/inputs', InputsRef, 'Routes' )


class CalendarSubscriptionsRef extends App.ControllerAppContent

  elements:
    'input[type=checkbox]': 'options'
    'output': 'output'

  events:
    'change input[type=checkbox]': 'onOptionsChange'
    'click .js-select': 'selectAll'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/calendar_subscriptions')()

  selectAll: (e) ->
    e.currentTarget.focus()
    e.currentTarget.select()

  onOptionsChange: =>
    optionCount = 3
    data = @options.serializeArray()
    modules = []
    translationTable =
      own: 'my'
      not_assigned: 'not assigned'
      new_open: 'new & open'
      pending: 'pending'
      escalating: 'escalating'

    # check if there is any data
    if data.length is 0
      @output
        .attr 'disabled', true
        .text 'No subscriptions active'
      return

    # check if all my tickets got selected
    own = data.filter((entry) -> entry.name.indexOf('own') >= 0)
    not_assigned = data.filter((entry) -> entry.name.indexOf('not_assigned') >= 0)

    if own.length > 0
      if own.length is optionCount
        modules.push 'all my tickets'
      else
        modules.push.apply modules, own.map (entry) ->
          [option, value] = entry.name.split('/')
          return "#{ translationTable[value] } #{ translationTable[option] }"
        modules[modules.length-1] += ' tickets'

    if not_assigned.length > 0
      if not_assigned.length is optionCount
        modules.push 'all not assigned tickets'
      else
        modules.push.apply modules, not_assigned.map (entry) ->
          [option, value] = entry.name.split('/')
          return "#{ translationTable[value] } #{ translationTable[option] }"
        modules[modules.length-1] += ' tickets'

    @output
      .attr 'disabled', false
      .text "Subscription to #{ @joinItems modules }:"

  joinItems: (items) ->
    switch items.length
      when 1 then return items[0]
      when 2 then return "#{ items[0] } and #{ items[1] }"
      else
        return "#{ items.slice(0, -1).join(', ') } and #{ items[items.length-1] }"


App.Config.set( 'layout_ref/calendar_subscriptions', CalendarSubscriptionsRef, 'Routes' )


class ButtonsRef extends App.ControllerAppContent

  elements:
    '.js-submitDropdown': 'buttonDropdown'

  events:
    'click .js-openDropdown':        'toggleMenu'
    'mouseenter .js-dropdownAction': 'onActionMouseEnter'
    'mouseleave .js-dropdownAction': 'onActionMouseLeave'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/buttons')

  toggleMenu: =>
    if @buttonDropdown.hasClass('is-open')
      @closeMenu()
      return
    @openMenu()

  closeMenu: =>
    @buttonDropdown.removeClass 'is-open'

  openMenu: =>
    @buttonDropdown.addClass 'is-open'

  onActionMouseEnter: (e) =>
    @$(e.currentTarget).addClass('is-active')

  onActionMouseLeave: (e) =>
    @$(e.currentTarget).removeClass('is-active')

App.Config.set( 'layout_ref/buttons', ButtonsRef, 'Routes' )

class MergeCustomerRef extends App.ControllerAppContent

  mergeTarget:
    firstname: 'Nicole',
    lastname: 'Braun',
    email: [
      {
        address: 'nicole.braun@zammad.com'
        main: true
      }
    ]

  mergeSource:
    firstname: 'Nicole',
    lastname: 'Müller',
    email: [
      {
        address: 'nicole.mueller@zammad.com'
        main: true
      },
      {
        address: 'nicole@mueller.de'
      }
    ]

  events:
    'change .merge-control select': 'onChange'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/merge_customer_view')

    new App.ControllerModal
      large: true
      head: "#{@mergeSource.firstname} #{@mergeSource.lastname}"
      headPrefix: 'Merge'
      contentInline: App.view('layout_ref/merge_customer')()
      buttonSubmit: 'Merge'
      buttonCancel: true
      container: @el

  onChange: ->


App.Config.set( 'layout_ref/merge_customer', MergeCustomerRef, 'Routes' )


class PrimaryEmailRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/primary_email')()

App.Config.set( 'layout_ref/primary_email', PrimaryEmailRef, 'Routes' )


class CustomerChatRef extends App.Controller

  questions: [
    {
      question: 'Der dümmste Bauer hat die dicksten ..?'
      answers: ['Kartoffeln']
    },
    {
      question: 'Welchen Wein besang einst Udo Jürgens?'
      answers: ['griechisch']
    },
    {
      question: 'Was behandelt ein Logopäde?'
      answers: ['Sprachstörung']
    },
    {
      question: 'In welcher Stadt ist das Porsche Stammwerk?'
      answers: ['Stuttgart']
    },
    {
      question: 'Wer erfand den legendären C64-Computer?'
      answers: ['Commodore']
    },
    {
      question: 'Im Englischen steht "Lost And Found" für ..?'
      answers: ['Fundbüro']
    },
    {
      question: 'Welches Möbelstück ist und war besonders in Sigmund Freuds Arbeitszimmer bekannt?'
      answers: ['Couch']
    },
    {
      question: 'Wenn es einem gut geht, lebt man "wie die Made im .."?'
      answers: ['Speck']
    },
    {
      question: 'Von welcher Sportart handelt der US-amerikanische Film "Rocky"?'
      answers: ['Boxen']
    },
    {
      question: 'Wo soll man hingehen, wenn man sich weit entfernen soll? Dahin wo ..?'
      answers: ['Pfeffer', 'wächst']
    },
    {
      question: 'Welches internationale Autokennzeichen hat Spanien?'
      answers: ['ES']
    },
    {
      question: 'Wenn man sich ärgert sagt man "Verdammt und .."?'
      answers: ['zugenäht']
    },
    {
      question: 'Bei welchem Spiel muss man ohne zu zittern Stäbchen sammeln?'
      answers: ['Mikado']
    },
    {
      question: 'Wann wurde Znuny gegründet?'
      answers: ['2012']
    }
  ]

  constructor: ->
    super

    @i = 0
    @chatWindows = []
    @totalQuestions = 7
    @answered = 0
    @correct = 0
    @wrong = 0
    @maxChats = 4

    @render()

    @interval(
      =>
        @updateNavMenu()
      6800
    )

  render: ->
    @html App.view('layout_ref/customer_chat')()

    @addChat()

    # @testChat @chatWindows[0], 100
    @initQuiz()

    @updateNavMenu()

  show: (params) =>

    # highlight navbar
    @navupdate '#layout_ref/customer_chat'

  randomCounter: (min, max) ->
    parseInt(Math.random() * (max - min) + min)

  counter: =>
    @randomCounter(0,100)

  switch: (state = undefined) ->

    # read state
    if state is undefined
      value = App.SessionStorage.get('chat_layout_ref')
      if value is undefined
        value = false
      return value

    # write state
    App.SessionStorage.set('chat_layout_ref', state)

  testChat: (chat, count) ->
    for i in [0..count]
      text = @questions[Math.floor(Math.random() * @questions.length)].question
      chat.addMessage text, if i % 2 then 'customer' else 'agent'

  addChat: ->
    chat = new ChatWindowRef
      name: "Quizmaster-#{ ++@i }"

    @on 'layout-has-changed', @propagateLayoutChange

    @$('.chat-workspace').append(chat.el)
    @chatWindows.push chat

  propagateLayoutChange: (event) =>
    # adjust scroll position on layoutChange

    for chat in @chatWindows
      chat.trigger 'layout-changed'

  initQuiz: ->
    @chatWindows[0].addStatusMessage('To start the quiz type <strong>Start</strong>')
    @chatWindows[0].bind 'answer', @startQuiz

  startQuiz: (answer) =>
    return false unless answer is 'Start'

    @chatWindows[0].unbind 'answer'

    @nextQuestion()

  nextQuestion: ->
    if not @questions.length
      @currentChat.addStatusMessage("Du hast #{ @correct } von #{ @totalQuestions } Fragen richtig beantwortet!")
      for chat in @chatWindows
        chat.unbind 'answer'
        if chat is not @currentChat
          chat.goOffline()
      return

    if @chatWindows.length < @maxChats and Math.random() < 0.2
      @addChat()
      randomWindowId = @chatWindows.length-1
    else
      # maybe take a chat offline
      if @chatWindows.length > 1 and Math.random() > 0.85
        randomWindowId = Math.floor(Math.random()*@chatWindows.length)
        [killedChat] = @chatWindows.splice randomWindowId, 1
        killedChat.goOffline()

      randomWindowId = Math.floor(Math.random()*@chatWindows.length)

    randomQuestionId = Math.floor(Math.random()*@questions.length)

    @currentQuestion = @questions.splice(randomQuestionId, 1)[0]

    newChat = @chatWindows[randomWindowId]

    messageDelay = 500

    if newChat != @currentChat
      @currentChat.unbind('answer') if @currentChat
      @currentChat = newChat
      @currentChat.bind 'answer', @onQuestionAnswer
      messageDelay = 1500

    @currentChat.showWritingLoader()

    setTimeout @currentChat.receiveMessage, messageDelay + Math.random() * 1000, @currentQuestion.question

  onQuestionAnswer: (answer) =>
    match = false

    for text in @currentQuestion.answers
      if answer.match( new RegExp(text,'i') )
        match = true

    @answered++

    if match
      @correct++
      @currentChat.receiveMessage _.shuffle(['😀','😃','😊','😍','😎','😏','👍','😌','😇','👌'])[0]
    else
      @wrong++
      @currentChat.receiveMessage _.shuffle(['👎','💩','😰','😩','😦','😧','😟','😠','😡','😞','😢','😒','😕'])[0]

    if @answerd is @totalQuestions
      @finishQuiz()
    else
      @nextQuestion()

# class CustomerChatRouter extends App.ControllerPermanent
#   constructor: (params) ->
#     super

#     # check authentication
#     @authenticateCheckRedirect()

#     App.TaskManager.execute(
#       key:        'CustomerChatRef'
#       controller: 'CustomerChatRef'
#       params:     {}
#       show:       true
#       persistent: true
#     )

App.Config.set( 'layout_ref/customer_chat', CustomerChatRef, 'Routes' )
# App.Config.set( 'CustomerChatRef', { controller: 'CustomerChatRef', permission: ['chat.agent'] }, 'permanentTask' )
# App.Config.set( 'CustomerChatRef', { prio: 1200, parent: '', name: 'Customer Chat', target: '#layout_ref/customer_chat', key: 'CustomerChatRef', permission: ['chat.agent'], class: 'chat' }, 'NavBar' )

class ChatWindowRef extends Spine.Controller
  @extend Spine.Events

  className: 'chat-window'

  events:
    'keydown .js-customerChatInput': 'onKeydown'
    'focus .js-customerChatInput':   'clearUnread'
    'click':                         'clearUnread'
    'click .js-send':                'sendMessage'
    'click .js-close':               'close'

  elements:
    '.js-customerChatInput': 'input'
    '.js-status':            'status'
    '.js-body':              'body'
    '.js-scrollHolder':      'scrollHolder'

  sound:
    message: new Audio('assets/sounds/chat_message.mp3')
    window: new Audio('assets/sounds/chat_new.mp3')

  constructor: ->
    super

    @showTimeEveryXMinutes = 1
    @lastTimestamp
    @lastAddedType
    @render()
    #@sound.window.play()

    @on 'layout-change', @scrollToBottom

  render: ->
    @html App.view('layout_ref/customer_chat_window')
      name: @options.name

    @el.one 'transitionend', @onTransitionend

    # make sure animation will run
    setTimeout (=> @el.addClass('is-open')), 0

    # @addMessage 'Hello. My name is Roger, how can I help you?', 'agent'

  onTransitionend: (event) =>
    # chat window is done with animation - adjust scroll-bars
    # of sibling chat windows
    @trigger 'layout-has-changed'

    if event.data and event.data.callback
      event.data.callback()

  close: =>
    @el.one 'transitionend', { callback: @release }, @onTransitionend
    @el.removeClass('is-open')

  release: =>
    @trigger 'closed'
    super

  clearUnread: =>
    @$('.chat-message--new').removeClass('chat-message--new')
    @updateModified(false)

  onKeydown: (event) =>
    TABKEY = 9
    ENTERKEY = 13

    switch event.keyCode
      when TABKEY
        allChatInputs = $('.js-customerChatInput').not('[disabled="disabled"]')
        chatCount = allChatInputs.size()
        index = allChatInputs.index(@input)

        if chatCount > 1
          switch index
            when chatCount-1
              if !event.shiftKey
                # State: tab without shift on last input
                # Jump to first input
                event.preventDefault()
                allChatInputs.eq(0).focus()
            when 0
              if event.shiftKey
                # State: tab with shift on first input
                # Jump to last input
                event.preventDefault()
                allChatInputs.eq(chatCount-1).focus()

      when ENTERKEY
        if !event.shiftKey
          event.preventDefault()
          @sendMessage()

  sendMessage: =>
    return if !@input.html()

    @addMessage @input.html(), 'agent'

    @trigger 'answer', @input.html()

    @input.html('')

  updateModified: (state) =>
    @status.toggleClass('is-modified', state)

  receiveMessage: (message) =>
    isFocused = @input.is(':focus')

    @removeWritingLoader()
    @addMessage(message, 'customer', !isFocused)

    if !isFocused
      @updateModified(true)
      @sound.message.play()

  addMessage: (message, sender, isNew) =>
    @maybeAddTimestamp()

    @lastAddedType = sender

    @body.append App.view('layout_ref/customer_chat_message')
      message: message
      sender: sender
      isNew: isNew
      timestamp: Date.now()

    @scrollToBottom()

  showWritingLoader: =>
    @maybeAddTimestamp()
    @body.append App.view('layout_ref/customer_chat_loader')()

    @scrollToBottom()

  removeWritingLoader: =>
    @$('.js-loader').remove()

  goOffline: =>
    @addStatusMessage("<strong>#{ @options.name }</strong>'s connection got closed")
    @status.attr('data-status', 'offline')
    @el.addClass('is-offline')
    @input.attr('disabled', true)

  maybeAddTimestamp: ->
    timestamp = Date.now()

    if !@lastTimestamp or timestamp - @lastTimestamp > @showTimeEveryXMinutes * 60000
      label = 'today'
      time = new Date().toTimeString().substr(0,5)
      if @lastAddedType is 'timestamp'
        # update last time
        @updateLastTimestamp label, time
        @lastTimestamp = timestamp
      else
        @addTimestamp label, time
        @lastTimestamp = timestamp
        @lastAddedType = 'timestamp'

  addTimestamp: (label, time) =>
    @body.append App.view('layout_ref/customer_chat_timestamp')
      label: label
      time: time

  updateLastTimestamp: (label, time) ->
    @body
      .find('.js-timestamp')
      .last()
      .replaceWith App.view('layout_ref/customer_chat_timestamp')
        label: label
        time: time

  addStatusMessage: (message) ->
    @body.append App.view('layout_ref/customer_chat_status_message')
      message: message

    @scrollToBottom()

  scrollToBottom: ->
    @scrollHolder.scrollTop(@scrollHolder.prop('scrollHeight'))


class AdminLoadRef extends App.ControllerAppContent

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/admin_loading')()

App.Config.set( 'layout_ref/admin_loading', AdminLoadRef, 'Routes' )


class TwitterConversationRef extends App.ControllerAppContent
  elements:
    '.js-textarea':                       'textarea'
    '.article-add':                       'articleNewEdit'
    '.article-add .textBubble':           'textBubble'
    '.editControls-item':                 'editControlItem'
    '.js-letterCount':                    'letterCount'
    '.js-signature':                      'signature'

  events:
    'input .js-textarea': 'updateLetterCount'

  textareaHeight:
    open:   88
    closed: 20

  maxTextLength: 280
  warningTextLength: 10

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/twitter_conversation')()

    @openTextarea null, true
    @updateLetterCount()

  updateLetterCount: (event) =>
    textLength = @maxTextLength - @textarea.text().length - @signature.text().length - 2
    className = switch
      when textLength < 0 then 'label-danger'
      when textLength < @warningTextLength then 'label-warning'
      else ''

    @letterCount
      .text textLength
      .removeClass 'label-danger label-warning'
      .addClass className

  openTextarea: (event, withoutAnimation) =>
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

App.Config.set( 'layout_ref/twitter_conversation', TwitterConversationRef, 'Routes' )

class UI extends App.ControllerAppContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/ui')()

App.Config.set( 'layout_ref/ui', UI, 'Routes' )

class ChatToTicketRef extends App.ControllerAppContent

  elements:
    '.js-scrollHolder': 'scrollHolder'
    '.js-boxFade': 'boxFade'
    '.js-attachments': 'attachments'
    '.js-chatBox': 'chatBox'

  events:
    'input .js-textInput': 'placeBoxFade'

  constructor: ->
    super
    @render()
    @scrollToBottom()
    @placeBoxFade()

  render: ->
    @html App.view('layout_ref/chat_to_ticket')()

  scrollToBottom: ->
    @scrollHolder.scrollTop(@scrollHolder.prop('scrollHeight'))

  placeBoxFade: =>
    @boxFade.height @chatBox.outerHeight()
    y1 = @attachments.offset().top - @boxFade.offset().top

    @boxFade.html App.view('layout_ref/boxFade')
      width: @attachments.offset().left - @boxFade.offset().left
      height: @boxFade.height()
      y1: y1
      y2: y1 + @attachments.outerHeight()

App.Config.set('layout_ref/chat_to_ticket', ChatToTicketRef, 'Routes')

class KnowledgeBaseAgentReaderRef extends App.ControllerAppContent
  className: 'flex knowledge-base vertical'

  elements:
    '.js-search': 'searchInput'

  events:
    'click [data-target]':   'onTargetClicked'
    'click .js-open-search': 'toggleSearch'

  constructor: ->
    super
    App.Utils.loadIconFont('anticon')
    @render()
    @level(1)

  render: ->
    @html App.view('layout_ref/kb_agent_reader_ref')()

  toggleSearch: (event) ->
    active = $(event.currentTarget).toggleClass('btn--primary')
    if $(event.currentTarget).is('.btn--primary')
      @el.find('.main[data-level]').addClass('hidden')
      @el.find('[data-level~="search"]').removeClass('hidden')
      @searchInput.focus()
    else
      @el.find("[data-level~=\"#{@currentLevel}\"]").removeClass('hidden')
      @el.find('[data-level~="search"]').addClass('hidden')

  onTargetClicked: (event) ->
    event.preventDefault()
    @level(event.currentTarget.dataset.target)

  level: (level) ->
    @currentLevel = level
    @el.find('[data-level]').addClass('hidden')
    @el.find("[data-level~=\"#{@currentLevel}\"]").removeClass('hidden')

App.Config.set('layout_ref/kb_agent_reader', KnowledgeBaseAgentReaderRef, 'Routes')

class KnowledgeBaseLinkTicketToAnswerRef extends App.ControllerAppContent
  constructor: ->
    super
    App.Utils.loadIconFont('anticon')
    @render()

  render: =>
    new App.ControllerModal
      head: 'Link Answer'
      buttonSubmit: false
      container: @el
      content: App.view('layout_ref/kb_link_ticket_to_answer_ref')

App.Config.set('layout_ref/kb_link_ticket_to_answer', KnowledgeBaseLinkTicketToAnswerRef, 'Routes')

class KnowledgeBaseLinkAnswerToAnswerRef extends App.ControllerAppContent
  elements:
    '.js-form': 'form'

  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/kb_link_answer_to_answer_ref')()

    new App.ControllerForm(
      grid: true
      params:
        category_id: 2
        translation_ids: [
          1
          2
        ]
        archived_at: null
        internal_at: null
        published_at: '2018-10-22T13:58:08.730Z'
        attachments: []
        id: 1
        translation:
          title: 'Lithium en-us'
          content:
            body:
              text: 'Lithium (from Greek: λίθος, translit. lithos, lit. "stone") is a chemical element with symbol Li and atomic number 3. It is a soft, silvery-white alkali metal. Under standard conditions, it is the lightest metal and the lightest solid element. Like all alkali metals, lithium is highly reactive and flammable, and is stored in mineral oil.'
              attachments: []
            id: 1
          answer_id: 1
          id: 1
      screen: 'agent'
      autofocus: true
      el: @form
      model:
        configure_attributes: [
          {
            name: 'translation::title'
            model: 'translation'
            display: 'Title'
            tag: 'input'
            grid_width: '1/2'
          }
          {
            name: 'category_id'
            model: 'answer'
            display: 'Category'
            tag: 'select'
            null: true
            options: [
              {
                value: 1
                name: 'Metal'
              }
              {
                value: 2
                name: 'Alkali metal'
              }
            ]
            grid_width: '1/2'
          }
          {
            name: 'translation::content::body'
            model: 'translation'
            display: 'Content'
            tag: 'richtext'
            buttons: [
              'link'
              'link_answer'
            ]
          }
        ]
    )

App.Config.set('layout_ref/kb_link_answer_to_answer', KnowledgeBaseLinkAnswerToAnswerRef, 'Routes')
App.Config.set('LayoutRef', { prio: 1600, parent: '#current_user', name: 'Layout Reference', translate: true, target: '#layout_ref', permission: [ 'admin' ] }, 'NavBarRight')
