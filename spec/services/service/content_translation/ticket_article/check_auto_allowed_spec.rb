# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Who is allowed is covered by spec/services/service/content_translation/ticket_article/auto_allowed_spec.rb.
RSpec.describe Service::ContentTranslation::TicketArticle::CheckAutoAllowed do
  subject(:service) { described_class.execute(user: create(:agent)) }

  it 'passes an allowed user' do
    Setting.set('content_translation_ticket_article_auto', true)

    expect { service }.not_to raise_error
  end

  it 'raises for a user who is not allowed' do
    Setting.set('content_translation_ticket_article_auto', false)

    expect { service }.to raise_error(Exceptions::Forbidden, 'Automatic translation of ticket articles is not available for you.')
  end
end
