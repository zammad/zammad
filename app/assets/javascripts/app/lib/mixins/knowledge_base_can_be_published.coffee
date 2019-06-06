InstanceMethods =
  canBePublished: -> true

  can_be_published_state: ->
    matching_time = (new Date()).getTime()

    switch
      when @date(@archived_at) < matching_time
        'archived'
      when @date(@published_at) < matching_time
        'published'
      when @date(@internal_at) < matching_time
        'internal'
      else
        'draft'

  can_be_published_by: (state = @can_be_published_state()) ->
    if state == 'draft'
      return

    user_id = @["#{state}_by_id"]

    App.User.find user_id

  can_be_published_at: (state = @can_be_published_state()) ->
    if state == 'draft'
      return @created_at

    @["#{state}_at"]

  can_be_published_state_css: ->
    "state-#{@can_be_published_state()}"

  can_be_published_quick_actions: ->
    switch @can_be_published_state()
      when 'published'
        ['archive']
      when 'internal'
        ['publish', 'archive']
      when 'draft'
        ['publish', 'internal']
      else
        []

  next_call_to_action: ->
    switch @can_be_published_state()
      when 'archived'
        ['unarchive']
      when 'published'
        ['archive']
      when 'internal'
        ['publish', 'archive']
      else
        ['publish', 'internal']

  can_be_published_publish_in_future: ->
    @date(@published_at) > (new Date()).getTime()

  can_be_published_archive_in_future: ->
    @date(@archived_at) > (new Date()).getTime()

  can_be_published_internal_in_future: ->
    @date(@internal_at) > (new Date()).getTime()

  is_internally_published: (kb_locale) ->
    state = @can_be_published_state()
    object_published = state == 'internal' || state == 'published'

    if !object_published
      return false

    if !@translation(kb_locale.id)
      return false

    true

  is_published: (kb_locale) ->
    if @can_be_published_state() isnt 'published'
      return false

    if !@translation(kb_locale.id)
      return false

    true


  date: (string) ->
    return undefined if !string
    new Date(string).getTime()

App.KnowledgeBaseCanBePublished =
  canBePublished: -> true

  extended: ->
    @include InstanceMethods
