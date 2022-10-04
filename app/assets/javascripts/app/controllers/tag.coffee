class Tag extends App.ControllerSubContent
  requiredPermission: 'admin.tag'
  header: __('Tags')
  events:
    'change .js-newTagSetting input': 'setTagNew'
    'submit .js-create': 'create'

  elements:
    '.js-newTagSetting input': 'tagNewSetting'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    currentNewTagSetting = @Config.get('tag_new') || true
    return if currentNewTagSetting is @lastNewTagSetting
    @lastNewTagSetting = currentNewTagSetting

    @html App.view('tag/index')()
    new Table(
      el: @$('.js-Table')
    )

  setTagNew: (e) =>
    value = @tagNewSetting.prop('checked')
    App.Setting.set('tag_new', value)

  create: (e) =>
    e.preventDefault()
    field = $(e.currentTarget).find('input[name]')
    name = field.val().trim()
    return if !name
    @ajax(
      type:  'POST'
      url:   "#{@apiPath}/tag_list"
      data:  JSON.stringify(name: name)
      success: (data, status, xhr) =>
        @html App.view('tag/index')()
        new Table(
          el: @$('.js-Table')
        )
    )

class Table extends App.Controller
  events:
    'click .js-delete': 'destroy'
    'click .js-edit': 'edit'
    'click .js-search': 'search'

  constructor: ->
    super
    @load()

  load: =>
    @ajax(
      id:    'tag_admin_list'
      type:  'GET'
      url:   "#{@apiPath}/tag_list"
      processData: true
      success: (data, status, xhr) =>
        @render(data)
    )

  render: (list) =>
    @html App.view('tag/table')(
      list: list
    )

  edit: (e) =>
    e.preventDefault()
    row = $(e.currentTarget).closest('tr')
    name = row.find('.js-name').text()
    id = row.data('id')
    new Edit(
      id: id
      name: name
      callback: @load
    )

  destroy: (e) ->
    e.preventDefault()
    e.stopPropagation()
    row = $(e.currentTarget).closest('tr')
    id = row.data('id')
    new DestroyConfirm(
      id: id
      row: row
    )

  search: (e) ->
    e.preventDefault()
    e.stopPropagation()
    item = $(e.target).closest('tr').find('.js-name').text()
    App.GlobalSearchWidget.search(item, 'tags')

class Edit extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Submit')
  head: __('Edit')
  small: true

  content: ->
    App.view('tag/edit')(
      id: @id
      name: @name
    )

  onSubmit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    @ajax(
      id:    'tag_admin_list'
      type:  'PUT'
      url:   "#{@apiPath}/tag_list/#{@id}"
      data:  JSON.stringify(
        id: @id
        name: params.name
      )
      success: (data, status, xhr) =>
        @callback()
        @close()
    )

class DestroyConfirm extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Yes')
  buttonClass: 'btn--danger'
  head: __('Confirmation')
  small: true

  content: ->
    App.i18n.translateContent('Do you really want to delete this object?')

  onSubmit: =>
    @ajax(
      id:    'tag_admin_list'
      type:  'DELETE'
      url:   "#{@apiPath}/tag_list/#{@id}"
      processData: true
      success: (data, status, xhr) =>
        @row.remove()
        @close()
    )

App.Config.set('Tags', { prio: 2320, name: __('Tags'), parent: '#manage', target: '#manage/tags', controller: Tag, permission: ['admin.tag'] }, 'NavBarAdmin')
