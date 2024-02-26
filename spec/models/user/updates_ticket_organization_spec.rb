# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User::UpdatesTicketOrganization, type: :model do
  subject(:ticket) { build(:ticket, customer: customer, organization: nil) }

  let(:customer) { create(:customer, :with_org) }

  context 'when ticket is created' do
    it 'automatically adopts the organization of its #customer' do
      expect { ticket.save }
        .to change(ticket, :organization).to(customer.organization)
    end
  end

  context 'when #customer.organization is updated' do
    context 'when set to nil' do
      it "automatically updates to #customer's new value" do
        ticket.save

        expect { customer.update(organization: nil) }.to change { ticket.reload.organization }.to(nil)
      end
    end

    context 'when #customer.organization is updated to a different organization' do
      let!(:old_org) { customer.organization }
      let!(:new_org) { create(:organization) }

      context "when 'ticket_organization_reassignment' is set to false" do
        before { Setting.set('ticket_organization_reassignment', false) }

        it "does not automatically update to #customer's new value" do
          ticket.save
          customer.update!(organization: new_org)

          expect(ticket.reload.organization).to eq(old_org)
        end
      end

      it "automatically updates to #customer's new value" do
        ticket.save

        expect { customer.update(organization: new_org) }.to change { ticket.reload.organization }.to(new_org)
      end

      it 'has made all changes with user id 1' do
        expect(ticket.updated_by.id).to eq 1
      end

      # https://github.com/zammad/zammad/issues/3952
      it 'does not send notifications' do
        allow(NotificationFactory::Mailer).to receive(:deliver)

        customer.update(organization: old_org)

        expect(NotificationFactory::Mailer).not_to have_received(:deliver)
      end
    end

    context 'when customer has secondary organizations' do
      let(:customer)                 { create(:customer, organization: old_primary_organization, organizations: [secondary_organization]) }
      let(:old_primary_organization) { create(:organization) }
      let(:new_primary_organization) { create(:organization) }
      let(:secondary_organization)   { create(:organization) }

      let(:tickets) do
        ticket_primary_org   = create(:ticket, customer: customer, organization: old_primary_organization)
        ticket_secondary_org = create(:ticket, customer: customer, organization: secondary_organization)

        [ticket_primary_org, ticket_secondary_org]
      end

      before { tickets }

      it 'updates ticket with primary organization and does not change ticket with secondary organization', :aggregate_failures do
        customer.update!(organization: new_primary_organization)

        expect(tickets.first.reload.organization).to eq(new_primary_organization)
        expect(tickets.last.reload.organization).to eq(secondary_organization)
      end

      context 'when customer has no organization assigned at all' do
        let(:customer) { create(:customer) }

        let(:tickets) do
          ticket_primary_org   = create(:ticket, customer: customer)
          ticket_secondary_org = create(:ticket, customer: customer)

          [ticket_primary_org, ticket_secondary_org]
        end

        it 'updates all ticket to contain the primary organization', :aggregate_failures do
          customer.update!(organization: new_primary_organization, organizations: [secondary_organization])

          expect(tickets.first.reload.organization).to eq(new_primary_organization)
          expect(tickets.last.reload.organization).to eq(new_primary_organization)
        end
      end
    end
  end
end
