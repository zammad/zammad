# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  it 'contains only ERB tags from the English base template in all translations', :aggregate_failures do
    Rails.root.join('app/views').glob('{mailer,messaging}/*/').each do |dir|
      en_file = dir.glob('en.*').first
      next if en_file.nil?

      en_tags = extract_erb_tags(en_file.read)

      dir.glob('*').each do |file|
        next if file == en_file

        translated_tags = extract_erb_tags(file.read)
        expect(translated_tags).to eq(en_tags),
                                   "#{file.relative_path_from(Rails.root)} has different ERB tags than English base.\n  " \
                                   "Expected: #{en_tags}\n  " \
                                   "Got:      #{translated_tags}"
      end
    end
  end

  def extract_erb_tags(content)
    content.scan(%r{<%(?!%).*?%>}m).map(&:strip)
  end
end
