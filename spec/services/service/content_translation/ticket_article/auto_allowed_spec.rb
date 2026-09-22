# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::TicketArticle::AutoAllowed do
  subject(:service) { described_class.execute(user: agent) }

  let(:agent) { create(:agent) }
  let(:role)  { agent.roles.first }

  before { Setting.set('content_translation_ticket_article_auto', true) }

  context 'without configured roles' do
    it 'allows every agent' do
      expect(service).to be(true)
    end
  end

  context 'with a user who is no agent' do
    subject(:service) { described_class.execute(user: create(:customer)) }

    it 'allows nobody' do
      expect(service).to be(false)
    end
  end

  context 'with the automatic translation switched off' do
    before { Setting.set('content_translation_ticket_article_auto', false) }

    it 'allows nobody' do
      expect(service).to be(false)
    end
  end

  context 'with configured roles' do
    before { Setting.set('content_translation_ticket_article_auto_role_ids', role_ids) }

    context 'when the user has one of them' do
      let(:role_ids) { [role.id] }

      it 'allows the user' do
        expect(service).to be(true)
      end
    end

    context 'when the ids are stored as strings' do
      let(:role_ids) { [role.id.to_s] }

      it 'allows the user' do
        expect(service).to be(true)
      end
    end

    context 'when the user has none of them' do
      let(:role_ids) { [create(:role).id] }

      it 'refuses the user' do
        expect(service).to be(false)
      end
    end
  end
end
