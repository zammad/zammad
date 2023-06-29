class App.TicketSharedDraftModal extends App.ControllerModal
  head:   __('Apply Shared Draft')
  events:
    'click .js-delete': 'onDelete'

  buttonClose:  true
  buttonCancel: true
  buttonSubmit: 'Apply'
  leftButtons: [
    {
      text: 'Delete',
      className: 'js-delete'
    }
  ]

  constructor: ->
    @contentView = new Content(shared_draft: arguments[0].shared_draft)
    super

    if @shared_draft.constructor.needsLoading
      @load()

    @controllerBind(@importCallbackName(), @attachmentsImported)

  content: ->
    @contentView.el

  importCallbackName: ->
    "import_attachments_done-#{@controllerId}"

  load: ->
    @startLoading()

    @ajax
      id: "shared_draft_#{@shared_draft.id}"
      type: 'GET'
      url: @apiPath + '/tickets/shared_drafts/' + @shared_draft.id
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @shared_draft_content = data.shared_draft_content

        @contentView.loadContent(@shared_draft_content)

        @stopLoading()
      error: =>
        @stopLoading()

  onSubmit: (e) ->
    if !@hasChanges
      @disable(true)
      @applyAttachments()
      return

    new App.TicketSharedDraftOverwriteModal(
      head:        __('Apply Draft')
      message:     __('There is existing content. Do you want to overwrite it?')
      onSaveDraft: =>
        @disable(true)
        @applyAttachments()
    )

  attachmentsImported: (options) =>
    if !options.success
      @disable(false)
      return

    @applyMeta(options)
    @cancel()

  disable: (toggle) ->
    @el.find('.js-submit').attr('disabled', toggle)

  applyAttachments: ->
    switch @shared_draft.constructor
      when App.TicketSharedDraftZoom
        App.Event.trigger('ui::ticket::import_draft_attachments', {
          shared_draft_id: @shared_draft.id,
          ticket_id:       @parent.ticket_id
          callbackName:    @importCallbackName()
        })
      when App.TicketSharedDraftStart
        App.Event.trigger('ticket_create_import_draft_attachments', {
          shared_draft_id: @shared_draft.id,
          callbackName: @importCallbackName()
        })

  applyMeta: (options) ->
    switch @shared_draft.constructor
      when App.TicketSharedDraftZoom
        container       = @parent.$('.article-add')
        newArticleAttrs = @shared_draft.new_article

        App.Event.trigger('ui::ticket::setArticleType', {
          ticket: { id: @parent.ticket_id }
          type:  { name: newArticleAttrs.type }
          article: newArticleAttrs
          nofocus: true
          shared_draft_id: @shared_draft.id
        })

        App.Event.trigger('ui::ticket::load', {
          ticket_id: @parent.ticket_id
          draft:     @shared_draft.ticket_attributes
        })
      when App.TicketSharedDraftStart
        content = _.clone @shared_draft_content
        content.group_id = @shared_draft.group_id
        content.attachments = options.attachments
        App.Event.trigger 'ticket_create_rerender', { options: content, shared_draft_id: @shared_draft.id }

  onDelete: (e) ->
    e.preventDefault()

    parent = @

    new App.ControllerModal
      container: @container
      buttonClose: true
      buttonCancel: true
      buttonSubmit: __('Yes')
      buttonClass: 'btn--danger'
      head: __('Are you sure?')
      small: true

      content: ->
        App.i18n.translateContent('Do you really want to delete this draft?')

      onSubmit: ->
        @startLoading()

        switch parent.shared_draft.constructor
          when App.TicketSharedDraftZoom
            @ajax
              id: 'ticket_shared_draft_delete'
              type: 'DELETE'
              url: @apiPath + '/tickets/' + parent.parent.ticket_id + '/shared_draft'
              success: (data, status, xhr) =>
                @stopLoading()
                @cancel()
                parent.cancel()
                parent.shared_draft.remove(clear: true)
                parent.parent.draftFetched()
          when App.TicketSharedDraftStart
            @ajax
              id: 'ticket_shared_draft_delete'
              type: 'DELETE'
              url: @apiPath + '/tickets/shared_drafts/' + parent.shared_draft.id
              success: (data, status, xhr) =>
                @stopLoading()
                @cancel()
                parent.cancel()
                parent.shared_draft.remove(clear: true)
                parent.parent.render()

class Content extends App.Controller
  constructor: ->
    super

    @render()

  body: ->
    switch @shared_draft.constructor
      when App.TicketSharedDraftZoom
        @shared_draft.new_article.body
      when App.TicketSharedDraftStart
        @shared_draft_content?.body

  author: ->
    App.User.find @shared_draft.updated_by_id

  timestamp: ->
    new Date(@shared_draft.updated_at)

  loadContent: (content) =>
    @shared_draft_content = content
    @render()

  render: ->
    @html App.view('ticket_shared_draft_modal')(
      body:      @body()
      name:      @author().displayName()
      timestamp: @timestamp()
    )

    new App.WidgetAvatar(
      el:        @$('.js-avatar')
      object_id: @shared_draft.updated_by_id
      size:      40
    )
