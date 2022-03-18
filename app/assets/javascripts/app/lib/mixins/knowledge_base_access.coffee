InstanceMethods =
  access: (kb_locale) ->
    permission_reader = App.Permission.findByAttribute('name', 'knowledge_base.reader')
    permission_editor = App.Permission.findByAttribute('name', 'knowledge_base.editor')

    permissions_effective = switch @constructor
      when App.KnowledgeBaseAnswer
        @category().permissions_effective
      when App.KnowledgeBaseCategory, App.KnowledgeBase
        @permissions_effective

    access = 'none'

    for role_id in App.User.current().role_ids
      kb_permission = _.findWhere(permissions_effective, { role_id: role_id })

      if kb_permission
        switch kb_permission.access
          when 'editor'
            return 'editor'
          when 'reader'
            access = 'reader'
          when 'none'
            access = 'reader' if kb_locale && @visiblePublicly(kb_locale)
      else if role = App.Role.find(role_id)
        if role.permission_ids.indexOf(permission_editor.id) > -1
          return 'editor'
        if role.permission_ids.indexOf(permission_reader.id) > -1
          access = 'reader'

    return access

App.KnowledgeBaseAccess =
  extended: ->
    @include InstanceMethods
