class IndexRouter extends App.Controller
  constructor: (params) ->
    super

    # get groups
    groups = App.Config.get('NavBarLevel4')
    groupsUnsorted = []
    for key, value of groups
      groupsUnsorted.push value

    @groupsSorted = _.sortBy( groupsUnsorted, (item) -> return item.prio )

    # get items of group
    for group in @groupsSorted
      items = App.Config.get('NavBarLevel44')
      itemsUnsorted = []
      for key, value of items
        if value.parent is group.target
          itemsUnsorted.push value

      group.items = _.sortBy( itemsUnsorted, (item) -> return item.prio )


    # set active item
    selectedItem = undefined
    for group in @groupsSorted
      if group.items
        for item in group.items
          if !@target && !selectedItem
            item.active = true
            selectedItem = item
          else if @target && item.target is '#manage/' + @target
            item.active = true
            selectedItem = item
          else if @target && item.target is '#settings/' + @target
            item.active = true
            selectedItem = item
          else if @target && item.target is '#channels/' + @target
            item.active = true
            selectedItem = item
          else if @target && item.target is '#system/' + @target
            item.active = true
            selectedItem = item
          else
            item.active = false

    @render(selectedItem)

    if selectedItem
      new selectedItem.controller(
        el: @el.find('.main')
      )

  render: (selectedItem) ->

    if !$('.nav-manage')[0]
      @html App.view('generic/navbar_l2')(
        groups:     @groupsSorted
        className: 'nav-manage'
      )
    if selectedItem
      @el.find('li').removeClass('active')
      @el.find('a[href="' + selectedItem.target + '"]').parent().addClass('active')


App.Config.set( 'manage', IndexRouter, 'Routes' )
App.Config.set( 'manage/:target', IndexRouter, 'Routes' )
App.Config.set( 'settings/:target', IndexRouter, 'Routes' )
App.Config.set( 'channels/:target', IndexRouter, 'Routes' )
App.Config.set( 'system/:target', IndexRouter, 'Routes' )

App.Config.set( 'Manage', { prio: 1000, name: 'Manage', target: '#manage', role: ['Admin'] }, 'NavBarLevel4' )
App.Config.set( 'Channels', { prio: 2500, name: 'Channels', target: '#channels', role: ['Admin'] }, 'NavBarLevel4' )
App.Config.set( 'Settings', { prio: 7000, name: 'Settings', target: '#settings', role: ['Admin'] }, 'NavBarLevel4' )
App.Config.set( 'System', { prio: 8000, name: 'System', target: '#system', role: ['Admin'] }, 'NavBarLevel4' )

