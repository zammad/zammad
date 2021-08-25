class App.CoreWorkflowCustomModule extends App.Model
  @configure 'CoreWorkflowCustomModule', 'name'
  @configure_attributes = [
    { name: 'name', display: 'Name', tag: 'input', type: 'text', null: false },
  ]

