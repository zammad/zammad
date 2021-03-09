class App.Webhook extends App.Model
  @configure 'Webhook', 'name', 'endpoint', 'signature_token', 'ssl_verify', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/webhooks'
  @configure_attributes = [
    { name: 'name',             display: 'Name',                      tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'endpoint',         display: 'Endpoint',                  tag: 'input',     type: 'text', limit: 300, null: false, placeholder: 'https://target.example.com/webhook' },
    { name: 'signature_token',  display: 'HMAC SHA1 Signature Token', tag: 'input',     type: 'text', limit: 100, null: true },
    { name: 'ssl_verify',       display: 'SSL Verify',                tag: 'boolean',   null: true, options: { true: 'yes', false: 'no'  }, default: true },
    { name: 'note',             display: 'Note',                      tag: 'textarea', note: '', limit: 250, null: true },
    { name: 'active',           display: 'Active',                    tag: 'active',    default: true },
    { name: 'updated_at',       display: 'Updated',                   tag: 'datetime',  readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'endpoint',
  ]

  @description = '''
Webhooks make it easy to send information about events within Zammad to third party systems via HTTP(S).

You can use Webhooks in Zammad to send Ticket, Article and Attachment data whenever a Trigger is performed. Just create and configure your Webhook with an HTTP(S) endpoint and relevant security settings, configure a Trigger to perform it.
'''

  displayName: ->
    return @name if !@endpoint
    if @active is false
      return "#{@name} (#{@endpoint}) (#{App.i18n.translateInline('inactive')})"
    "#{@name} (#{@endpoint})"
