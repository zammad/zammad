class App.ExternalCredential extends App.Model
  @configure 'ExternalCredential', 'name', 'credentials'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/external_credentials'
