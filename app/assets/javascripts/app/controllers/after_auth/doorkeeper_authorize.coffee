class App.AfterAuthDoorKeeperAuthorize extends App.Controller
  constructor: (params) ->
    super(params)
    window.location.href = params.data?.url if params.data?.url
