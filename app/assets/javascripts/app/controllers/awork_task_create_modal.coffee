class App.AworkTaskCreateModal extends App.ControllerModal
  buttonCancel: true

  constructor: (params) ->
    super

    @ticket = params['ticket']
    @taskLinks = params['taskLinks']

  content: =>
    content = $( App.view('integration/awork/task_create_modal')(
      data: {
        name: @nameTemplate(),
        description: @descriptionTemplate()
      }
    ))

    @nameInput = content.find('#awork-task-create-name')

    @descriptionTextArea = new App.WidgetTextModule(
      el: content.find('#awork-task-create-description'),
      data:{
        user:   App.Session.get(),
        config: App.Config.all(),
      }
    )

    content

  nameTemplate: =>
    "#{__('Ticket')}: \"#{@ticket.title}\""

  descriptionTemplate: =>
    descriptionTemplate = ''
    @descriptionTicketLink = "<a href=\"#{location.origin}#ticket/zoom/#{@ticket.id}\" target=\"_blank\">#{@ticket.title}</a>"
    if @ticket.article_count > 0
      latestArticleId = @ticket.article_ids.slice(-1)
      latestArticle = App.TicketArticle.find(latestArticleId)
      if latestArticle.body
        descriptionTemplate += "<blockquote>#{latestArticle.body.replace(/\n/g, '<br>')}</blockquote>"

    @prependLink(descriptionTemplate)

  prependLink: (str) =>
    "#{__('Ticket')}: #{@descriptionTicketLink}" + str

  onSubmit: (e) =>
    @startLoading()

    if !@nameInput.val()
      @stopLoading()
      @close()
      return

    nameValue         = @nameInput.val()
    # check if ticket-link is contained description and prepend it if not
    descriptionValue  = if @descriptionTextArea.el.find('.richtext-content').html().includes(@descriptionTicketLink) then @descriptionTextArea.el.find('.richtext-content').html() else @prependLink(@descriptionTextArea.el.find('.richtext-content').html())

    @ajax(
      id:    'create-task'
      type:  'POST'
      url:   "#{@apiPath}/integration/awork/tasks/create"
      data:  JSON.stringify({
        linked_tasks: @taskLinks,
        ticket_id: @ticket.id,
        create_task: {
          name: nameValue,
          description: descriptionValue
        }
      })
      success: (data, status, xhr) =>
        if data.result is 'failed'
          @stopLoading()
          @close()

          new App.ControllerErrorModal(
            message: data.message
            container: @el.closest('.content')
          )
          return

        App.Event.trigger 'notify', {
          type: 'success'
          msg:  App.i18n.translateContent('Update successful.')
        }

        @callback(@taskLinks)
        @stopLoading()
        @close()
    )