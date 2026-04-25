# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::ChangeVisibility do
  subject(:service_result) { described_class.with_current_user(user).execute(article:, internal: new_internal) }

  let(:article)      { create(:ticket_article, internal: internal) }
  let(:internal)     { false }
  let(:new_internal) { true }

  describe '#execute' do
    context 'when user has access' do
      let(:user) { create(:agent, groups: [article.ticket.group]) }

      context 'when public' do
        it 'sets to internal' do
          expect { service_result }
            .to change(article, :internal).to(true)
        end
      end

      context 'when internal' do
        let(:internal)     { true }
        let(:new_internal) { false }

        it 'sets to public' do
          expect { service_result }
            .to change(article, :internal).to(false)
        end
      end
    end

    context 'when user has no access' do
      let(:user) { create(:customer) }

      it 'fails with Pundit error' do
        expect { service_result }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
