class App.SSLCertificate extends App.Model
  @configure 'SSLCertificate', 'name', 'active', 'certificate', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ssl_certificates'
  @configure_attributes = []
  @configure_overview = ['subject']
  @configure_delete = true
