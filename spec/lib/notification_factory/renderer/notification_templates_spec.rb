# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'NotificationFactory::Renderer > Notification Templates' do # rubocop:disable RSpec/DescribeClass

  matcher :render_without_errors do
    match do
      NotificationFactory::Renderer.new(
        objects:  { changes: { field: 'value' }, article:, ticket:, recipient:, current_user: },
        template: actual.read,
        trusted:  true,
      ).render
    rescue => e
      @error = e
      false
    end

    failure_message do
      "Expected #{actual.relative_path_from(Rails.root)} to render without errors, but it failed with error: #{@error}"
    end
  end

  # Cache the objects to speed the tests up.
  let(:current_user) { create(:agent) }
  let(:recipient)    { create(:customer) }
  let(:ticket)       { create(:ticket) }
  let(:article)      { create(:ticket_article, ticket:) }

  it 'renders English and translated notification templates without syntax errors', :aggregate_failures do
    Rails.root.join('app/views').glob('{mailer,messaging}/*/*.erb').each do |file| # rubocop:disable RSpec/IteratedExpectation
      expect(file).to render_without_errors
    end
  end
end
