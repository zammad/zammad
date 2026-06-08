class App.AIAgentType extends App.Model
  @configure 'AIAgentType', 'name', 'description', 'custom', 'definition', 'action_definition', 'form_schema'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ai_agents/types'
  @configure_translate = true
