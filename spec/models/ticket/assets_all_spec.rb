# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::AssetsAll do
  describe '#all_assets', current_user_id: 1 do
    subject(:instance) { described_class.new(user, ticket) }

    let(:group)            { create(:group) }
    let(:agent)            { create(:agent, groups: [group]) }
    let(:other_agent)      { create(:agent, groups: [group]) }
    let(:ticket)           { create(:ticket, owner: agent, group:) }
    let(:draft)            { create(:ticket_shared_draft_zoom, ticket:) }
    let(:article_internal) { create(:ticket_article, ticket:, internal: true) }
    let(:article_email)    { create(:ticket_article, :outbound_email, ticket:) }
    let(:checklist)        { create(:checklist, ticket:) }
    let(:tag_name)         { 'tag1' }
    let(:mention)          { create(:mention, mentionable: ticket, user: other_agent) }
    let(:link)             { create(:link, from: ticket, to: other_ticket) }
    let(:time_accounting)  { create(:ticket_time_accounting, ticket:) }
    let(:other_ticket)     { create(:ticket, group:) }

    before do
      ticket && draft && article_email && article_internal && checklist

      ticket.tag_add(tag_name)
      mention
      link
      time_accounting
    end

    context 'when user is agent' do
      let(:user) { agent }

      it 'returns full response' do
        expect(instance.all_assets).to include(
          ticket_id:          ticket.id,
          ticket_article_ids: [article_email.id, article_internal.id],
          links:              [{ 'link_object' => 'Ticket', 'link_object_value' => other_ticket.id, 'link_type' => 'normal' }],
          tags:               [tag_name],
          mentions:           [mention.id],
          time_accountings:   [time_accounting.slice(:id, :ticket_id, :ticket_article_id, :time_unit, :type_id)],
          form_meta:          be_present,
          assets:             be_present,
        )
      end

      it 'returns all assets' do
        assets = instance.all_assets[:assets]

        objects = [ticket, article_internal, article_email, draft, checklist, mention, other_ticket]

        expect(assets).to include_assets_of(objects)
      end
    end

    context 'when user is customer' do
      let(:user) { ticket.customer }

      it 'returns customer-suited response' do
        expect(instance.all_assets).to include(
          ticket_id:          ticket.id,
          ticket_article_ids: [article_email.id],
          links:              be_blank,
          tags:               [tag_name],
          mentions:           [mention.id],
          time_accountings:   [time_accounting.slice(:id, :ticket_id, :ticket_article_id, :time_unit, :type_id)],
          form_meta:          be_present,
          assets:             be_present,
        )
      end

      it 'returns customer-suited assets' do
        assets = instance.all_assets[:assets]

        objects = [ticket, article_email, mention]

        expect(assets).to include_assets_of(objects)
      end

      it 'does not return agent-only assets' do
        assets = instance.all_assets[:assets]

        agent_only_objects = [article_internal, checklist, other_ticket]

        expect(assets).not_to include_assets_of(agent_only_objects)
      end
    end
  end
end
