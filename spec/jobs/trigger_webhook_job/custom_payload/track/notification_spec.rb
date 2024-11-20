# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerWebhookJob::CustomPayload::Track::Notification do
  let(:ticket)  { create(:ticket) }
  let(:article) { create(:ticket_article, body: "Text with\nnew line.") }

  let(:event) do
    {
      type:      'info',
      execution: 'trigger',
      changes:   { 'state' => %w[open closed] },
      user_id:   1,
    }
  end

  matcher :render_without_errors do
    match do
      folder_name = File.basename(File.dirname(actual))
      event_name = folder_name.sub(%r{^ticket_}, '')

      locale = File.basename(actual, '.md.erb')
      Setting.set('locale_default', locale)
      event[:type] = event_name

      described_class.generate({ ticket:, article: }, { event: })
    rescue => e
      @error = e
      false
    end

    failure_message do
      "Expected #{actual.relative_path_from(Rails.root)} to render without errors, but it failed with error: #{@error}"
    end
  end

  it 'notification templates without syntax errors', :aggregate_failures do
    Rails.root.join('app/views').glob('messaging/*/*.erb').each do |file| # rubocop:disable RSpec/IteratedExpectation
      expect(file).to render_without_errors
    end
  end
end
