# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HasTicketCreateScreenImpact, type: :job do

  context 'with groups' do
    let!(:group) { create(:group) }

    it 'create should enqueue no job' do
      collection_jobs = enqueued_jobs.select do |job|
        job[:job] == TicketCreateScreenJob
      end
      expect(collection_jobs.count).to be(1)
    end

    context 'updating attribute' do
      before do
        clear_jobs
      end

      context 'name' do
        it 'enqueues a job' do
          expect { group.update!(name: 'new name') }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end

      context 'active' do
        it 'enqueues a job' do
          expect { group.update!(active: false) }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end

      context 'updated_at' do
        it 'enqueues a job' do
          expect { group.touch }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end
    end

    it 'delete should enqueue no job' do
      clear_jobs
      expect { group.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
    end
  end

  context 'with roles' do
    let!(:role) { create(:role) }

    it 'create should enqueue no job' do
      collection_jobs = enqueued_jobs.select do |job|
        job[:job] == TicketCreateScreenJob
      end
      expect(collection_jobs.count).to be(1)
    end

    context 'updating attribute' do

      before do
        clear_jobs
      end

      context 'name' do
        it 'enqueues a job' do
          expect { role.update!(name: 'new name') }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end

      context 'active' do
        it 'enqueues a job' do
          expect { role.update!(active: false) }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end

      context 'updated_at' do
        it 'enqueues no job' do
          expect { role.touch }.to have_enqueued_job(TicketCreateScreenJob)
        end
      end
    end

    it 'delete should enqueue no job' do
      clear_jobs
      expect { role.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
    end
  end

  context 'with users' do

    let!(:customer) { create(:user, roles: Role.where(name: 'Customer')) }
    let!(:agent) { create(:user, roles: Role.where(name: 'Agent')) }
    let!(:admin) { create(:user, roles: Role.where(name: 'Admin')) }

    let(:customer_new) { create(:user, roles: Role.where(name: 'Customer')) }
    let(:agent_new) { create(:user, roles: Role.where(name: 'Agent')) }
    let(:admin_new) { create(:user, roles: Role.where(name: 'Admin')) }

    context 'creating' do
      before do
        clear_jobs
      end

      it 'customer should enqueue no job' do
        customer_new
        collection_jobs = enqueued_jobs.select do |job|
          job[:job] == TicketCreateScreenJob
        end
        expect(collection_jobs.count).to be(0)
      end

      it 'agent should enqueue a job' do
        agent_new
        collection_jobs = enqueued_jobs.select do |job|
          job[:job] == TicketCreateScreenJob
        end
        expect(collection_jobs.count).to be(1)
      end

      it 'admin should enqueue no job' do
        admin_new
        collection_jobs = enqueued_jobs.select do |job|
          job[:job] == TicketCreateScreenJob
        end
        expect(collection_jobs.count).to be(0)
      end
    end

    context 'updating attribute' do
      before do
        clear_jobs
      end

      context 'firstname field for' do
        it 'customer should enqueue no job' do
          expect { customer.update!(firstname: 'new firstname') }.not_to have_enqueued_job(TicketCreateScreenJob)
        end

        it 'agent should enqueue a job' do
          expect { agent.update!(firstname: 'new firstname') }.to have_enqueued_job(TicketCreateScreenJob)
        end

        it 'admin should enqueue no job' do
          expect { admin.update!(firstname: 'new firstname') }.not_to have_enqueued_job(TicketCreateScreenJob)
        end
      end

      context 'active field for' do
        it 'customer should enqueue no job' do
          expect { customer.update!(active: false) }.not_to have_enqueued_job(TicketCreateScreenJob)
        end

        it 'agent should enqueue a job' do
          expect { agent.update!(active: false) }.to have_enqueued_job(TicketCreateScreenJob)
        end

        it 'admin should enqueue no job' do
          admin_new # Prevend "Minimum one user needs to have admin permissions."
          clear_jobs
          expect { admin.update!(active: false) }.not_to have_enqueued_job(TicketCreateScreenJob)
        end
      end
    end

    context 'deleting' do
      before do
        clear_jobs
      end

      it 'customer should enqueue a job' do
        expect { customer.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
      end

      it 'agent should enqueue a job' do
        expect { agent.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
      end

      it 'admin should enqueue a job' do
        expect { admin.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
      end
    end

  end

end
