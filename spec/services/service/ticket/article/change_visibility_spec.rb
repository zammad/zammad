# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::ChangeVisibility do
  subject(:service) { described_class.new(current_user: user) }

  let(:article) { create(:ticket_article, internal: internal) }

  describe '#execute' do
    context 'when user has access' do
      let(:user) { create(:agent, groups: [article.ticket.group]) }

      context 'when public' do
        let(:internal) { false }

        it 'sets to internal' do
          expect { service.execute(article: article, internal: true) }
            .to change(article, :internal).to(true)
        end
      end

      context 'when internal' do
        let(:internal) { true }

        it 'sets to public' do
          expect { service.execute(article: article, internal: false) }
            .to change(article, :internal).to(false)
        end
      end
    end

    context 'when user has no access' do
      let(:user)     { create(:customer) }
      let(:internal) { false }

      it 'fails with Pundit error' do
        expect { service.execute(article: article, internal: true) }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
