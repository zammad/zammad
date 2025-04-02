class App.WidgetSharedDraft extends App.Controller
  constructor: ->
    super
    @subscribeId = App.TicketSharedDraftStart.subscribe(@render)
    @render()

  events:
    'click .shared-draft-item': 'clicked'
    'click .js-create':         'create'
    'click .js-update':         'update'
    'input #shared_draft_name': 'sharedDraftNameChanged'

  elements:
    '#shared_draft_name': 'sharedDraftNameInput'

  render: =>
    active_draft = App.TicketSharedDraftStart.find(@active_draft_id)

    @html App.view('widget/shared_draft')(
      shared_drafts: @visibleDrafts()
      active_draft:  active_draft
    )

  visibleDrafts: ->
    App.TicketSharedDraftStart.findAllByAttribute 'group_id', parseInt(@group_id)

  clicked: (e) ->
    shared_draft_id = e.currentTarget.getAttribute('shared-draft-id')
    draft           = App.TicketSharedDraftStart.find shared_draft_id
    hasChanges      = App.TaskManager.worker(@taskKey).changed()

    new App.TicketSharedDraftModal(
      container:    @el.closest('.content')
      shared_draft: draft
      hasChanges:   hasChanges
      parent:       @
    )

  getParams: ->
    form    = @formParam(@el.closest('.content').find('.ticket-create'))
    meta    = @formParam(@el)
    form_id = form.form_id

    delete form.form_id

    return false if meta.name.trim() == ''

    form.body = App.Utils.signatureRemoveByHtml(form.body)

    JSON.stringify({
      name:     meta.name
      group_id: form.group_id
      form_id:  form_id
      content:  form
    })

  success: (data, status, xhr) =>
    App.Collection.loadAssets(data.assets)
    App.Event.trigger 'ticket_create_shared_draft_saved', { shared_draft_id: data.shared_draft_id }
    @render()

  highlightError: ->
    @sharedDraftNameInput
      .addClass('has-error')
      .focus()

    false

  sharedDraftNameChanged: (e) ->
    @sharedDraftNameInput.removeClass('has-error')

  create: (e) ->
    @onAction(e,
      id: 'shared_drafts_create'
      type: 'POST'
      url: @apiPath + '/tickets/shared_drafts'
    )

  update: (e) ->
    @onAction(e,
      id: 'shared_drafts_update'
      type: 'PATCH'
      url: @apiPath + '/tickets/shared_drafts/' + @active_draft_id
    )

  onAction: (e, options) ->
    e.preventDefault()

    params = @getParams()

    return @highlightError() if !params

    @ajax _.extend(options, { data: params, success: @success })

  release: =>
    if @subscribeId
      App.TicketSharedDraftStart.unsubscribe(@subscribeId)

    super
