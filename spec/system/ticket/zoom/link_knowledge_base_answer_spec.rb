# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Link knowledge base answer', authenticated_as: :authenticate, type: :system do
  describe 'Link knowledge base answer' do
    include_context 'basic Knowledge Base'

    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }

    def authenticate
      translation
      true
    end

    shared_examples 'verify linking' do |elasticsearch:|
      before do
        if elasticsearch
          searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
        end

        visit "#ticket/zoom/#{ticket.id}"
      end

      it 'allows to look up an answer' do
        within :active_content do
          find('.link_kb_answers')

          within '.link_kb_answers' do
            find('.js-add').click

            find('.js-input').send_keys translation.title

            find(%(li[data-value="#{translation.id}"])).click

            expect(find('.link_kb_answers ol')).to have_text translation.title
          end
        end
      end
    end

    context 'with Elasticsearch', searchindex: true do
      include_examples 'verify linking', elasticsearch: true
    end

    context 'without Elasticsearch' do
      include_examples 'verify linking', elasticsearch: false
    end
  end

end
