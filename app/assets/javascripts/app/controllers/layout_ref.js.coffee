class Index extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/index')()

App.Config.set( 'layout_ref', Index, 'Routes' )


class Content extends App.ControllerContent
  constructor: ->
    super
    @render()

  render: ->
    @html App.view('layout_ref/content')()

App.Config.set( 'layout_ref/content', Content, 'Routes' )


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

    controller = new App.ControllerForm(
      model: App.User
      autofocus: true
    )

    @show(controller.form)

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

    form = App.view('layout_ref/content')()

    @show(form)

  onHide: =>
    window.history.back()



App.Config.set( 'layout_ref/modal_text', ModalText, 'Routes' )



class ContentSidebarTabsRight extends App.ControllerContent
  elements:
    '.tabsSidebar'  : 'sidebar'

  constructor: ->
    super
    @render()

    items = [
        head: 'Ticket Settings'
        name: 'ticket'
        icon: 'message'
      ,
        head: 'Customer'
        name: 'customer'
        icon: 'person'
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

App.Config.set( 'LayoutRef', { prio: 1700, parent: '#current_user', name: 'Layout Reference', target: '#layout_ref', role: [ 'Admin' ] }, 'NavBarRight' )
