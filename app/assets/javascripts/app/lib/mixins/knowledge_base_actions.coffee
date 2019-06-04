InstanceMethods =
  contentSidebarActions: (kb_locale) ->
    buttons = []

    if @constructor.canBePublished?()
      buttons.push {
        iconName: 'eye'
        name:     'Visibility'
        action:   'visibility'
        cssClass: 'btn--success'
        disabled: @isNew()
      }

    if !(@ instanceof App.KnowledgeBase)
      buttons.push {
        iconName: 'trash'
        name:     'Delete'
        action:   'delete'
        cssClass: 'btn--danger'
        disabled: @isNew()
      }

    buttons

App.KnowledgeBaseActions =
  extended: ->
    @include InstanceMethods
