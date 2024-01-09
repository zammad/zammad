# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DataPrivacyTask, type: :model do
  describe 'validations' do
    it 'uses DataPrivacyTaskValidator' do
      expect_any_instance_of(Validations::DataPrivacyTaskValidator).to receive(:validate)

      create(:data_privacy_task)
    end
  end

  describe '#perform', aggregate_failures: true do
    let(:task) { create(:data_privacy_task, deletable: deletable) }

    context 'when deletable is already deleted' do
      let(:organization) { create(:organization, name: 'test') }
      let(:deletable)    { create(:customer, organization: organization) }

      it 'sets no error message when user is already deleted' do
        task
        deletable.destroy
        task.perform
        expect(task.reload.state).to eq('completed')
      end
    end

    context 'when deleting a user' do
      let(:deletable) { create(:agent) }

      it 'deletes the user' do
        task.perform

        expect(User).not_to exist(deletable.id)
      end

      context 'when user belongs to an organization' do
        let(:organization) { create(:organization) }

        before { organization.members << deletable }

        it 'deletes the user only' do
          task.perform

          expect(User).not_to exist(deletable.id)
          expect(Organization).to exist(organization.id)
        end

        context 'when organization shall be deleted' do
          before do
            task.preferences[:delete_organization] = 'true'
            task.save!
          end

          it 'deletes the user and organization' do
            task.perform

            expect(User).not_to exist(deletable.id)
            expect(Organization).not_to exist(organization.id)
          end

          context 'when organization has more members' do
            let(:other_agent) { create(:agent) }

            before { organization.members << other_agent }

            it 'deletes the original user only' do
              task.perform

              expect(User).not_to exist(deletable.id)
              expect(Organization).to exist(organization.id)
              expect(User).to exist(other_agent.id)
            end
          end

          context 'when a secondary organization exists' do
            let(:other_organization) { create(:organization) }

            before { other_organization.secondary_members << deletable }

            it 'deletes the original user and main organization only' do
              task.perform

              expect(User).not_to exist(deletable.id)
              expect(Organization).not_to exist(organization.id)
              expect(Organization).to exist(other_organization.id)
            end
          end
        end
      end
    end

    context 'when deleting a ticket' do
      let(:deletable) { create(:ticket) }

      it 'deletes the ticket' do
        task.perform
        expect(Ticket).not_to exist(deletable.id)
      end

      context 'when ticket has a customer that belongs to an organization' do
        let(:customer)     { create(:customer) }
        let(:organization) { create(:organization) }

        before do
          organization.members << customer
          deletable.update!(
            customer_id:     customer.id,
            organization_id: organization.id,
          )
        end

        it 'deletes the ticket only' do
          task.perform

          expect(Ticket).not_to exist(deletable.id)
          expect(User).to exist(customer.id)
          expect(Organization).to exist(organization.id)
        end
      end
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

      let(:owner_tickets) { create_list(:ticket, 3, owner: user) }

      before { owner_tickets }

      it 'stores the numbers' do
        expect(task[:preferences][:owner_tickets]).to eq(owner_tickets.reverse.map(&:number))
      end

      context 'when a lot of tickets exist' do
        before do
          stub_const('DataPrivacyTask::MAX_PREVIEW_TICKETS', 5)
        end

        let(:owner_tickets) { create_list(:ticket, 6, owner: user) }

        it 'stores maximum amount', :aggregate_failures do
          expect(task[:preferences][:owner_tickets].size).to be(5)
          expect(task[:preferences][:owner_tickets_count]).to be(6)
        end
      end
    end

    context 'when User is a customer of Tickets' do

      let(:customer_tickets) { create_list(:ticket, 3, customer: user) }

      before { customer_tickets }

      it 'stores the numbers' do
        expect(task[:preferences][:customer_tickets]).to eq(customer_tickets.reverse.map(&:number))
      end

      context 'when a lot of tickets exist' do
        before do
          stub_const('DataPrivacyTask::MAX_PREVIEW_TICKETS', 5)
        end

        let(:customer_tickets) { create_list(:ticket, 6, customer: user) }

        it 'stores the maximum amount', :aggregate_failures do
          expect(task[:preferences][:customer_tickets].size).to be(5)
          expect(task[:preferences][:customer_tickets_count]).to be(6)
        end
      end
    end

    context 'when deletable is a ticket' do
      let(:ticket)          { create(:ticket, title: 'Doomed ticket') }
      let(:task)            { create(:data_privacy_task, deletable: ticket) }
      let(:deleted_tickets) { [ticket.number] }

      let(:pseudonymous_data) do
        {
          'title' => 'D*d t*t',
        }
      end

      it 'creates pseudonymous representation' do
        expect(task[:preferences][:ticket]).to eq(pseudonymous_data)
      end

      it 'remembers deleted ticket number', :aggregate_failures do
        expect(task[:preferences][:customer_tickets]).to eq(deleted_tickets)
        expect(task[:preferences][:customer_tickets_count]).to eq(1)
      end
    end
  end

  describe '.cleanup' do
    let(:task) { create(:data_privacy_task) }

    it 'does not delete new tasks' do
      task
      described_class.cleanup
      expect { task.reload }.not_to raise_error
    end

    it 'does delete old tasks' do
      travel_to 13.months.ago
      task
      travel_back
      described_class.cleanup
      expect { task.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does make sure that the cleanup returns truthy value for scheduler' do
      expect(described_class.cleanup).to be(true)
    end
  end
end
