class App.CoreWorkflowCustomModule extends App.Model
  @configure 'CoreWorkflowCustomModule', 'name'
  @configure_attributes = [
    { name: 'name', display: __('Name'), tag: 'input', type: 'text', null: false },
  ]
