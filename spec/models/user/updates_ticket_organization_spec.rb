# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      it 'automatically updates to #customer’s new value' do
        ticket.save

        expect { customer.update(organization: nil) }
          .to change { ticket.reload.organization }.to(nil)
      end
    end

    context 'when #customer.organization is updated to a different organization' do
      let(:old_org) { customer.organization }
      let(:new_org) { create(:organization) }

      it 'automatically updates to #customer’s new value' do
        ticket.save

        expect { customer.update(organization: new_org) }
          .to change { ticket.reload.organization }.to(new_org)
      end

      it 'has made all changes with user id 1' do
        expect(ticket.updated_by.id).to eq 1
      end

      # https://github.com/zammad/zammad/issues/3952
      it 'does not send notifications' do
        allow(NotificationFactory::Mailer).to receive(:send)

        customer.update(organization: old_org)

        expect(NotificationFactory::Mailer).not_to have_received(:send)
      end
    end
  end
end
