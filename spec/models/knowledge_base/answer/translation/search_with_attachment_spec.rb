# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, type: :model, current_user_id: 1, searchindex: 1 do
  include_context 'basic Knowledge Base'

  let(:user)     { create(:admin) }
  let(:filename) { 'test.rtf' }
  let(:query)    { 'RTF document' }

  context 'search with attachment' do
    before do
      configure_elasticsearch(required: true, rebuild: true) do
        published_answer.add_attachment File.open "spec/fixtures/upload/#{filename}"
      end
    end

    it do
      expect(described_class.search(query: query, current_user: user))
        .to include published_answer.translations.first
    end
  end
end
