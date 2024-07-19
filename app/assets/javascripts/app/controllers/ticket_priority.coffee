class TicketPriority extends App.ControllerSubContent
  @requiredPermission: 'admin.ticket_priority'
  header: __('Ticket Priority')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'TicketPriority'
      defaultSortBy: 'name'
      handlers: [@formHandler]
      pageData:
        home:      'ticket_priorities'
        object:    __('Ticket Priority')
        objects:   __('Ticket Priorities')
        navupdate: '#ticket_priorities'
        buttons: [
          { name: __('New Priority'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend: {
          customActions: [
            {
              name: 'set_default_create'
              display: __('Set default for new tickets')
              icon: 'reload'
              class: 'js-setDefaultCreate'
              callback: (id) =>
                @setDefaultPriority(id)
              available: (object) ->
                object.active and not object.default_create
            }
          ]
        }
      container: @el.closest('.content')
    )

  formHandler: (params, attribute, attributes, classname, form, ui) ->
    form.find('[data-attribute-name="ui_icon"]').show()

    return if App.Config.get('ui_ticket_priority_icons') and form.find('[name="ui_color"]').val()

    # Hide the "highlight icon" selection in case:
    #   - `ui_ticket_priority_icons` setting is disabled
    #   - `ui_color` form field is not set
    form.find('[data-attribute-name="ui_icon"]').hide()

  setDefaultPriority: (id) ->
    currentItem = App.TicketPriority.findByAttribute('default_create', true)
    selectedItem = App.TicketPriority.find(id)

    return if currentItem.id is selectedItem.id

    selectedItem.updateAttribute('default_create', true)
    currentItem?.refresh(default_create: false)

App.Config.set('TicketPriority', { prio: 3325, name: __('Ticket Priorities'), parent: '#manage', target: '#manage/ticket_priorities', controller: TicketPriority, permission: ['admin.object'], hidden: true }, 'NavBarAdmin')
