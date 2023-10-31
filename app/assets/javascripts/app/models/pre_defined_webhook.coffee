class App.PreDefinedWebhook extends App.Model
  @configure 'PreDefinedWebhook', 'name', 'custom_payload', 'fields'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/webhooks/pre_defined'
  @configure_translate = true
