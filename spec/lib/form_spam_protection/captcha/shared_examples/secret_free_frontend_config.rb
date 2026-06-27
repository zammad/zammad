# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Every provider's frontend configuration is served to the public form widget, so
# it must never carry the secret or API key. Uses a distinctive value so the
# assertion can't pass by coincidence regardless of where the value is nested.
RSpec.shared_examples 'a captcha that keeps secrets out of the frontend config' do
  subject(:provider) { described_class.new }

  before do
    Setting.set('form_ticket_create_captcha_options', {
                  'sitekey'    => 'site',
                  'secret'     => 'super-secret-value',
                  'api_key'    => 'super-secret-value',
                  'project_id' => 'proj',
                })
  end

  it 'never exposes the secret or API key to the frontend' do
    expect(provider.frontend_config.to_s).not_to include('super-secret-value')
  end
end
