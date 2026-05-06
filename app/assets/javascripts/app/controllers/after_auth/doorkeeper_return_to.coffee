class App.AfterAuthDoorkeeperReturnTo extends App.Controller
  constructor: (params) ->
    super(params)
    url = params.data?.url
    window.location.href = url if typeof url is 'string' and url.length > 0
