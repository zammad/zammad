class ElectronEvents extends App.Controller
  constructor: ->
    return if !window.require
    electron = window.require('electron')
    return if !electron
    remote = electron.remote
    ipc = electron.ipcRenderer
    super

    @controllerBind('window-title-set', (arg) ->
      ipc.send('window-title-set', arg)
    )
    @controllerBind('online_notification_counter', (e) ->
      setBadge(e)
    )
    ipc.off('global-shortcut').on('global-shortcut', (e, arg) ->
      App.Event.trigger('global-shortcut', arg)
    )

    Menu = remote.Menu
    MenuItem = remote.MenuItem

    createDefault = ->
      menu = new Menu()
      menu.append(new MenuItem(
        label: 'Cut',
        role: 'cut'
      ))
      menu.append(new MenuItem(
        label: 'Copy',
        role: 'copy'
      ))
      menu.append(new MenuItem(
        label: 'Paste',
        role: 'paste'
      ))
      menu.append(new MenuItem(
        label: 'Select All',
        role: 'selectall'
      ))
      menu

    menu = createDefault()
    window.addEventListener('contextmenu', (e) ->
      menu.popup(remote.getCurrentWindow())
      false
    )

    badgeDataURL = (text) ->
      scale = 2 # should rely display dpi
      size = 16 * scale
      canvas = document.createElement('canvas')
      canvas.setAttribute('width', size)
      canvas.setAttribute('height', size)
      ctx = canvas.getContext('2d')

      # circle
      ctx.fillStyle = '#FF1744' # Material Red A400
      ctx.beginPath()
      ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2)
      ctx.fill()

      # text
      ctx.fillStyle = '#ffffff'
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.font = (10 * scale) + 'px sans-serif'
      ctx.fillText(text, size / 2, size / 2, size)

      canvas.toDataURL()

    setBadgeWindows = (content) ->
      sendBadge = (dataURL, description) ->
        electron.ipcRenderer.send('win32-overlay', {
          overlayDataURL: dataURL,
          description: description,
          content: content,
        })

      if content isnt ''
        dataURL = badgeDataURL(content.toString())
        sendBadge(dataURL, 'You have unread messages (' + content + ')')
      else
        sendBadge(null, 'You have no unread messages')

    setBadgeOSX = (content) ->
      remote.app.dock.setBadge(content)

    setBadge = (content) ->
      if process.platform is 'win32'
        setBadgeWindows(content)
      else if process.platform is 'darwin'
        setBadgeOSX(content)

App.Config.set('aaa_electron_events', ElectronEvents, 'Plugins')
