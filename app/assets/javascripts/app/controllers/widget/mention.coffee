class App.WidgetMention extends App.Controller
  events:
    'click .js-subscribe': 'subscribe'
    'click .js-unsubscribe': 'unsubscribe'
  elements:
    '.js-subscribe input[type=button]': 'subscribeButton'
    '.js-unsubscribe input[type=button]': 'unsubscribeButton'

  constructor: ->
    super

    @mentions = []
    App.Event.bind('Mention:create Mention:destroy',
      (data) =>
        return if !data
        return if data.mentionable_type isnt 'Ticket'
        return if data.mentionable_id isnt @object.id
        @fetch()
    )
    @render()

  fetch: =>
    App.Mention.fetchMentionable(
      'Ticket',
      @object.id,
      (data) =>
        @mentions = data.record_ids
        App.Collection.loadAssets(data.assets)
        @render()
    )

  reload: (mentions) =>
    @mentions = mentions
    @render()

  render: =>
    subscribed = false
    mentions   = []
    counter    = 1
    for id in @mentions
      mention = App.Mention.find(id)
      continue if !mention

      user = App.User.find(mention.user_id)
      continue if !user
      continue if !user.active

      if mention.user_id is App.Session.get().id
        subscribed = true

      # no break because we need to check if user is subscribed
      continue if counter > 10

      css            = ''
      mention.access = true
      if !@object.isAccessibleBy(user, 'read')
        css            = 'avatar--inactive'
        mention.access = false

      mention.avatar = user.avatar('30', '', css)

      mentions.push(mention)
      counter++

    @html App.view('widget/mention')(
      subscribed: subscribed
      mentions: mentions
    )

  subscribe: (e) =>
    e.preventDefault()
    e.stopPropagation()
    @subscribeButton.prop('readonly', true)
    @subscribeButton.prop('disabled', true)

    mention = new App.Mention
    mention.load(
      mentionable_type: 'Ticket'
      mentionable_id: @object.id
      user_id: App.Session.get().id
    )
    mention.save(
      done: =>
        @subscribeButton.prop('readonly', false)
        @subscribeButton.prop('disabled', false)
        $(e.currentTarget).addClass('hidden')
        $(e.currentTarget).closest('form').find('.js-unsubscribe').removeClass('hidden')
    )

  unsubscribe: (e) =>
    e.preventDefault()
    e.stopPropagation()
    @unsubscribeButton.prop('readonly', true)
    @unsubscribeButton.prop('disabled', true)

    for id in @mentions
      mention = App.Mention.find(id)
      continue if !mention
      continue if mention.user_id isnt App.Session.get().id

      mention.destroy(
        done: =>
          @unsubscribeButton.prop('readonly', false)
          @unsubscribeButton.prop('disabled', false)
          $(e.currentTarget).addClass('hidden')
          $(e.currentTarget).closest('form').find('.js-subscribe').removeClass('hidden')
      )

      break
