class App.PublicLink extends App.Model
  @configure 'PublicLink', 'link', 'title', 'description', 'screen', 'new_tab', 'prio'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/public_links'
  @configure_attributes = [
    { name: 'link', display: __('Link'), tag: 'input', type: 'text', limit: 500, 'null': false, placeholder: 'https://link' },
    { name: 'title', display: __('Title'), tag: 'input', type: 'text', limit: 200, 'null': false },
    { name: 'description', display: __('Description (shown as title tag for screen readers)'), tag: 'input', type: 'text', limit: 200, 'null': true },
    { name: 'screen', display: __('Context'), tag: 'multiselect', options: { login: __('Login Screen'), signup: __('Signup Screen'), password_reset: __('Forgot Password Screen') }, default: ['login'], 'null': false, multiple: true },
    { name: 'new_tab', display: __('Open in new tab'), tag: 'select', options: { true: __('yes'), false: __('no'), }, default: true, 'null': false },
    { name: 'prio', display: __('Prio'), readonly: 1 },
  ]

  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'title',
    'link',
    'new_tab',
  ]

  @description = __('''
You can define links which are shown e.g. in the footer of Zammad's login screen. These have many purposes, such as displaying a data privacy page for all people using your Zammad instance.
''')
