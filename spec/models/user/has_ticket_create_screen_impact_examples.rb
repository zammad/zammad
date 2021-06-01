# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'User::HasTicketCreateScreenImpact' do

  describe '#push_ticket_create_screen', performs_jobs: true do
    shared_examples 'relevant User Role' do |role|

      context "relevant User Role is '#{role}'" do

        subject { create(:user, roles: Role.where(name: role)) }

        context 'creating a record' do
          it 'enqueues TicketCreateScreenJob' do
            expect { subject }.to have_enqueued_job(TicketCreateScreenJob)
          end
        end

        context 'record exists' do

          before do
            subject
            clear_jobs
          end

          context 'attribute updated' do
            it 'enqueues TicketCreateScreenJob' do
              expect { subject.update!(firstname: 'new firstname') }.to have_enqueued_job(TicketCreateScreenJob)
            end

            context 'permission association changes' do

              context 'Group' do

                let!(:group) { create(:group) }

                before { clear_jobs }

                it 'enqueues TicketCreateScreenJob' do
                  expect do
                    subject.group_names_access_map = {
                      group.name => ['full'],
                    }
                  end.to have_enqueued_job(TicketCreateScreenJob)
                end
              end

              context 'Role' do
                context 'to relevant' do

                  let!(:roles) { create_list(:agent_role, 1) }

                  before { clear_jobs }

                  it 'enqueues TicketCreateScreenJob' do
                    expect { subject.update!(roles: roles) }.to have_enqueued_job(TicketCreateScreenJob)
                  end
                end

                context 'to irrelevant' do

                  let!(:roles) { create_list(:role, 3) }

                  before { clear_jobs }

                  it 'enqueues TicketCreateScreenJob' do
                    expect { subject.update!(roles: roles) }.to have_enqueued_job(TicketCreateScreenJob)
                  end
                end
              end
            end
          end

          context 'record is deleted' do
            it 'enqueues TicketCreateScreenJob' do
              expect { subject.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
            end
          end
        end
      end
    end

    shared_examples 'irrelevant User Role' do |role|

      context "irrelevant User Role is '#{role}'" do

        subject { create(:user, roles: Role.where(name: role)) }

        context 'creating a record' do
          it 'does not enqueue TicketCreateScreenJob job' do
            expect { subject }.not_to have_enqueued_job(TicketCreateScreenJob)
          end
        end

        context 'record exists' do

          before do
            subject
            clear_jobs
          end

          context 'attribute updated' do
            it 'enqueues no TicketCreateScreenJob job' do
              expect { subject.update!(firstname: 'new firstname') }.not_to have_enqueued_job(TicketCreateScreenJob)
            end

            context 'permission association changes', last_admin_check: false do

              context 'Group' do

                let!(:group) { create(:group) }

                before { clear_jobs }

                it 'enqueues TicketCreateScreenJob' do
                  expect do
                    subject.group_names_access_map = {
                      group.name => ['full'],
                    }
                  end.to have_enqueued_job(TicketCreateScreenJob)
                end
              end

              context 'Role' do

                context 'to relevant' do

                  let!(:roles) { create_list(:agent_role, 3) }

                  before { clear_jobs }

                  it 'enqueues TicketCreateScreenJob' do
                    expect { subject.update!(roles: roles) }.to have_enqueued_job(TicketCreateScreenJob)
                  end
                end

                context 'to irrelevant' do

                  let!(:roles) { create_list(:role, 3) }

                  before { clear_jobs }

                  it 'does not enqueue TicketCreateScreenJob' do
                    expect { subject.update!(roles: roles) }.not_to have_enqueued_job(TicketCreateScreenJob)
                  end
                end
              end
            end
          end

          context 'record is deleted' do
            it 'enqueues TicketCreateScreenJob job' do
              expect { subject.destroy! }.to have_enqueued_job(TicketCreateScreenJob)
            end
          end
        end
      end
    end

    include_examples 'relevant User Role', 'Agent'
    include_examples 'irrelevant User Role', 'Customer'
    include_examples 'irrelevant User Role', 'Admin'
  end
end
