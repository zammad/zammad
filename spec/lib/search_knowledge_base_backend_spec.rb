require 'rails_helper'

RSpec.describe SearchKnowledgeBaseBackend do
  include_context 'basic Knowledge Base'

  let(:instance) { described_class.new options }
  let(:user)     { create(:admin) }

  let(:options) do
    {
      knowledge_base: knowledge_base,
      locale:         primary_locale,
      scope:          nil
    }
  end

  context 'with ES', searchindex: true do
    before do
      configure_elasticsearch(required: true, rebuild: true) do
        published_answer
      end
    end

    describe '#search' do
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

  context 'with (out) ES is identical' do
    [true, false].each do |val|
      context "when ES=#{val}", searchindex: val do
        before do
          if val
            configure_elasticsearch(required: true, rebuild: true) do
              published_answer
            end
          else
            published_answer
          end
        end

        let(:first_result) { instance.search(published_answer.translations.first.title, user: user).first }

        it 'ID is an Integer' do
          expect(first_result.dig(:id)).to be_a(Integer)
        end
      end
    end
  end
end
