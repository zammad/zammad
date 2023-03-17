class App.Webhook extends App.Model
  @configure 'Webhook', 'name', 'endpoint', 'signature_token', 'ssl_verify', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/webhooks'
  @configure_attributes = [
    { name: 'name',             display: __('Name'),                      tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'endpoint',         display: __('Endpoint'),                  tag: 'input',     type: 'text', limit: 300, null: false, placeholder: 'https://target.example.com/webhook' },
    { name: 'signature_token',  display: __('HMAC SHA1 Signature Token'), tag: 'input',     type: 'text', limit: 100, null: true },
    { name: 'ssl_verify',       display: __('SSL Verify'),                tag: 'boolean',   null: true, translate: true, options: { true: 'yes', false: 'no'  }, default: true },
    { name: 'note',             display: __('Note'),                      tag: 'textarea', note: '', limit: 250, null: true },
    { name: 'active',           display: __('Active'),                    tag: 'active',    default: true },
    { name: 'updated_at',       display: __('Updated'),                   tag: 'datetime',  readonly: 1 },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'endpoint',
  ]

  @description = __('''
Webhooks make it easy to send information about events within Zammad to third-party systems via HTTP(S).

You can use webhooks in Zammad to send ticket, article, and attachment data whenever a trigger is performed. Just create and configure your webhook with an HTTP(S) endpoint and relevant security settings, then configure a trigger to perform it.
''')

  displayName: ->
    return @name if !@endpoint
    if @active is false
      return "#{@name} (#{@endpoint}) (#{App.i18n.translateInline('inactive')})"
    "#{@name} (#{@endpoint})"
