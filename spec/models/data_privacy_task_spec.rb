# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DataPrivacyTask, type: :model do
  describe '.perform' do
    let(:organization) { create(:organization, name: 'test') }
    let!(:admin) { create(:admin) }
    let(:user) { create(:customer, organization: organization) }

    it 'blocks other objects than user objects' do
      expect { create(:data_privacy_task, deletable: create(:chat)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Deletable is not a User')
    end

    it 'blocks the multiple deletion tasks for the same user' do
      create(:data_privacy_task, deletable: user)
      expect { create(:data_privacy_task, deletable: user) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Deletable has an existing DataPrivacyTask queued')
    end

    it 'blocks deletion task for user id 1' do
      expect { create(:data_privacy_task, deletable: User.find(1)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Deletable is undeletable system User with ID 1')
    end

    it 'blocks deletion task for yourself' do
      UserInfo.current_user_id = user.id
      expect { create(:data_privacy_task, deletable: user) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Deletable is your current account')
    end

    it 'blocks deletion task for last admin' do
      expect { create(:data_privacy_task, deletable: admin) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Deletable is last account with admin permissions')
    end

    it 'allows deletion task for last two admins' do
      create(:admin)
      admin = create(:admin)
      expect(create(:data_privacy_task, deletable: admin)).to be_truthy
    end

    it 'sets the failed state when task failed' do
      task = create(:data_privacy_task, deletable: user)
      user.destroy
      task.perform
      expect(task.reload.state).to eq('failed')
    end

    it 'sets an error message when task failed' do
      task = create(:data_privacy_task, deletable: user)
      user.destroy
      task.perform
      expect(task.reload.preferences[:error]).to eq("ERROR: #<ActiveRecord::RecordNotFound: Couldn't find User with 'id'=#{user.id}>")
    end
  end

  describe '#prepare_deletion_preview' do

    let(:organization) { create(:organization, name: 'Zammad GmbH') }
    let(:user) { create(:customer, firstname: 'Nicole', lastname: 'Braun', organization: organization, email: 'secret@example.com') }
    let(:task) { create(:data_privacy_task, deletable: user) }

    context 'when storing user data' do

      let(:pseudonymous_data) do
        {
          'firstname'    => 'N*e',
          'lastname'     => 'B*n',
          'email'        => 's*t@e*e.com',
          'organization' => 'Z*d G*H',
        }
      end

      it 'creates pseudonymous representation' do
        expect(task[:preferences][:user]).to eq(pseudonymous_data)
      end
    end

    context 'when User is owner of Tickets' do

      let!(:owner_tickets) { create_list(:ticket, 3, owner: user) }

      it 'stores the numbers' do
        expect(task[:preferences][:owner_tickets]).to eq(owner_tickets.reverse.map(&:number))
      end
    end

    context 'when User is customer of Tickets' do

      let!(:customer_tickets) { create_list(:ticket, 3, customer: user) }

      it 'stores the numbers' do
        expect(task[:preferences][:customer_tickets]).to eq(customer_tickets.reverse.map(&:number))
      end
    end
  end
end
