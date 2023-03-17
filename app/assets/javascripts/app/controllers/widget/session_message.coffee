class App.SessionMessage extends App.ControllerModal
  showTrySupport: true

  onCancel: (e) =>
    if @forceReload
      @windowReload(e)

  onClose: (e) =>
    if @forceReload
      @windowReload(e)

  onSubmit: (e) =>
    if @forceReload
      @windowReload(e)
    else
      @close()
