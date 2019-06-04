class App.KnowledgeBaseServerSnippet extends App.ControllerModal
  head: 'Web Server Configuration'
  className: 'modal modal-knowledge-base-server-snippet'
  buttonSubmit: false
  initalFormParamsIgnore: true
  servers: [
    {
      id:  'nginx'
      name:   'Nginx'
      active: true
    }, {
      id:   'apache'
      name:    'Apache'
    }
  ]

  content: ->
    for server in @servers
      server.snippet = @snippets[server.id]

    $(App.view('knowledge_base/server_snippet')(
      address_type: @address_type
      address: @address
      servers: @servers
    ))
