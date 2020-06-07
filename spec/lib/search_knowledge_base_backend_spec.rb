require 'rails_helper'

RSpec.describe SearchKnowledgeBaseBackend, searchindex: true do
  include_context 'basic Knowledge Base'

  before do
    configure_elasticsearch(required: true, rebuild: true) do
      published_answer
    end
  end

  describe '#search' do
    let(:instance) { described_class.new options }
    let(:user)     { create(:admin) }

    context 'when highlight enabled' do
      let(:options) do
        {
          knowledge_base:    knowledge_base,
          locale:            primary_locale,
          scope:             nil,
          highlight_enabled: true
        }
      end

      # https://github.com/zammad/zammad/issues/3070
      it 'lists item with an attachment' do
        expect(instance.search('Hello World', user: user)).to be_present
      end
    end
  end
end
