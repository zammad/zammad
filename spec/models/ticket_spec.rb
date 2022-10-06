# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/can_csv_import_examples'
require 'models/concerns/checks_core_workflow_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_tags_examples'
require 'models/concerns/has_taskbars_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/tag/writes_to_ticket_history_examples'
require 'models/ticket/calls_stats_ticket_reopen_log_examples'
require 'models/ticket/enqueues_user_ticket_counter_job_examples'
require 'models/ticket/escalation_examples'
require 'models/ticket/resets_pending_time_seconds_examples'
require 'models/ticket/sets_close_time_examples'
require 'models/ticket/sets_last_owner_update_time_examples'
require 'models/ticket/selector_2_sql_examples'

RSpec.describe Ticket, type: :model do
  subject(:ticket) { create(:ticket) }

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'CanCsvImport'
  it_behaves_like 'ChecksCoreWorkflow'
  it_behaves_like 'HasHistory', history_relation_object: ['Ticket::Article', 'Mention', 'Ticket::SharedDraftZoom']
  it_behaves_like 'HasTags'
  it_behaves_like 'TagWritesToTicketHistory'
  it_behaves_like 'HasTaskbars'
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ticket
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'Ticket::Escalation'
  it_behaves_like 'TicketCallsStatsTicketReopenLog'
  it_behaves_like 'TicketEnqueuesTicketUserTicketCounterJob'
  it_behaves_like 'TicketResetsPendingTimeSeconds'
  it_behaves_like 'TicketSetsCloseTime'
  it_behaves_like 'TicketSetsLastOwnerUpdateTime'
  it_behaves_like 'TicketSelector2Sql'

  describe 'Class methods:' do
    describe '.selectors' do
      # https://github.com/zammad/zammad/issues/1769
      context 'when matching multiple tickets, each with multiple articles' do
        let(:tickets) { create_list(:ticket, 2) }

        before do
          create(:ticket_article, ticket: tickets.first, from: 'asdf1@blubselector.de')
          create(:ticket_article, ticket: tickets.first, from: 'asdf2@blubselector.de')
          create(:ticket_article, ticket: tickets.first, from: 'asdf3@blubselector.de')
          create(:ticket_article, ticket: tickets.last, from: 'asdf4@blubselector.de')
          create(:ticket_article, ticket: tickets.last, from: 'asdf5@blubselector.de')
          create(:ticket_article, ticket: tickets.last, from: 'asdf6@blubselector.de')
        end

        let(:condition) do
          {
            'article.from' => {
              operator: 'contains',
              value:    'blubselector.de',
            },
          }
        end

        it 'returns a list of unique tickets (i.e., no duplicates)' do
          expect(described_class.selectors(condition, limit: 100, access: 'full'))
            .to match_array([2, tickets.to_a])
        end
      end

      context 'when customer has multiple organizations' do
        let(:organization1) { create(:organization) }
        let(:organization2) { create(:organization) }
        let(:organization3) { create(:organization) }
        let(:customer)      { create(:customer, organization: organization1, organizations: [organization2, organization3]) }
        let(:ticket1)       { create(:ticket, customer: customer, organization: organization1) }
        let(:ticket2)       { create(:ticket, customer: customer, organization: organization2) }
        let(:ticket3)       { create(:ticket, customer: customer, organization: organization3) }

        before do
          ticket1 && ticket2 && ticket3
        end

        context 'when current user organization is used' do
          let(:condition) do
            {
              'ticket.organization_id' => {
                operator:      'is', # is not
                pre_condition: 'current_user.organization_id',
              },
            }
          end

          it 'returns the customer tickets' do
            expect(described_class.selectors(condition, limit: 100, access: 'full', current_user: customer))
              .to match_array([3, include(ticket1, ticket2, ticket3)])
          end
        end
      end
    end
  end

  describe 'Instance methods:' do
    describe '#merge_to' do
      let(:target_ticket) { create(:ticket) }

      context 'when source ticket has Links' do
        let(:linked_tickets) { create_list(:ticket, 3) }
        let(:links)          { linked_tickets.map { |l| create(:link, from: ticket, to: l) } }

        it 'reassigns all links to the target ticket after merge' do
          expect { ticket.merge_to(ticket_id: target_ticket.id, user_id: 1) }
            .to change { links.each(&:reload).map(&:link_object_source_value) }
            .to(Array.new(3) { target_ticket.id })
        end
      end

      context 'when attempting to cross-merge (i.e., to merge B → A after merging A → B)' do
        before { target_ticket.merge_to(ticket_id: ticket.id, user_id: 1) }

        it 'raises an error' do
          expect { ticket.merge_to(ticket_id: target_ticket.id, user_id: 1) }
            .to raise_error('ticket already merged, no merge into merged ticket possible')
        end
      end

      context 'when attempting to self-merge (i.e., to merge A → A)' do
        it 'raises an error' do
          expect { ticket.merge_to(ticket_id: ticket.id, user_id: 1) }
            .to raise_error("Can't merge ticket with itself!")
        end
      end

      context 'when both tickets are linked with the same parent (parent->child)' do
        let(:parent) { create(:ticket) }

        before do
          create(:link,
                 link_type:                'child',
                 link_object_source_value: ticket.id,
                 link_object_target_value: parent.id)
          create(:link,
                 link_type:                'child',
                 link_object_source_value: target_ticket.id,
                 link_object_target_value: parent.id)

          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
        end

        it 'does remove the link from the merged ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: ticket.id
          )
          expect(links.count).to eq(1) # one link to the source ticket (no parent link)
        end

        it 'does not remove the link from the target ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: target_ticket.id
          )
          expect(links.count).to eq(2) # one link to the merged ticket + parent link
        end
      end

      context 'when both tickets are linked with the same parent (child->parent)' do
        let(:parent) { create(:ticket) }

        before do
          create(:link,
                 link_type:                'child',
                 link_object_source_value: parent.id,
                 link_object_target_value: ticket.id)
          create(:link,
                 link_type:                'child',
                 link_object_source_value: parent.id,
                 link_object_target_value: target_ticket.id)

          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
        end

        it 'does remove the link from the merged ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: ticket.id
          )
          expect(links.count).to eq(1) # one link to the source ticket (no parent link)
        end

        it 'does not remove the link from the target ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: target_ticket.id
          )
          expect(links.count).to eq(2) # one link to the merged ticket + parent link
        end
      end

      context 'when both tickets are linked with the same parent (different link types)' do
        let(:parent) { create(:ticket) }

        before do
          create(:link,
                 link_type:                'normal',
                 link_object_source_value: parent.id,
                 link_object_target_value: ticket.id)
          create(:link,
                 link_type:                'child',
                 link_object_source_value: parent.id,
                 link_object_target_value: target_ticket.id)

          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
        end

        it 'does remove the link from the merged ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: ticket.id
          )
          expect(links.count).to eq(1) # one link to the source ticket (no normal link)
        end

        it 'does not remove the link from the target ticket' do
          links = Link.list(
            link_object:       'Ticket',
            link_object_value: target_ticket.id
          )
          expect(links.count).to eq(3) # one lin to the merged ticket + parent link + normal link
        end
      end

      context 'when both tickets having mentions to the same user' do
        let(:watcher) { create(:agent) }

        before do
          create(:mention, mentionable: ticket, user: watcher)
          create(:mention, mentionable: target_ticket, user: watcher)
          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
        end

        it 'does remove the link from the merged ticket' do
          expect(target_ticket.mentions.count).to eq(1) # one mention to watcher user
        end
      end

      context 'when merging' do
        let(:merge_user) { create(:user) }

        before do
          # create target ticket early
          # to avoid a race condition
          # when creating the history entries
          target_ticket
          travel 5.minutes

          ticket.merge_to(ticket_id: target_ticket.id, user_id: merge_user.id)
        end

        # Issue #2469 - Add information "Ticket merged" to History
        it 'creates history entries in both the origin ticket and the target ticket' do
          expect(target_ticket.history_get.size).to eq 2

          target_history = target_ticket.history_get.last
          expect(target_history['object']).to eq 'Ticket'
          expect(target_history['type']).to eq 'received_merge'
          expect(target_history['created_by_id']).to eq merge_user.id
          expect(target_history['o_id']).to eq target_ticket.id
          expect(target_history['id_to']).to eq target_ticket.id
          expect(target_history['id_from']).to eq ticket.id

          expect(ticket.history_get.size).to eq 4

          origin_history = ticket.reload.history_get[1]
          expect(origin_history['object']).to eq 'Ticket'
          expect(origin_history['type']).to eq 'merged_into'
          expect(origin_history['created_by_id']).to eq merge_user.id
          expect(origin_history['o_id']).to eq ticket.id
          expect(origin_history['id_to']).to eq target_ticket.id
          expect(origin_history['id_from']).to eq ticket.id
        end

        it 'sends ExternalSync.migrate' do
          allow(ExternalSync).to receive(:migrate)

          ticket.merge_to(ticket_id: target_ticket.id, user_id: merge_user.id)

          expect(ExternalSync).to have_received(:migrate).with('Ticket', ticket.id, target_ticket.id)
        end

        # Issue #2960 - Ticket removal of merged / linked tickets doesn't remove references
        context 'and deleting the origin ticket' do
          it 'adds reference number and title to the target ticket' do
            expect { ticket.destroy }
              .to change { target_ticket.history_get.find { |elem| elem.fetch('type') == 'received_merge' }['value_from'] }
              .to("##{ticket.number} #{ticket.title}")
          end
        end

        # Issue #2960 - Ticket removal of merged / linked tickets doesn't remove references
        context 'and deleting the target ticket' do
          it 'adds reference number and title to the origin ticket' do
            expect { target_ticket.destroy }
              .to change { ticket.history_get.find { |elem| elem.fetch('type') == 'merged_into' }['value_to'] }
              .to("##{target_ticket.number} #{target_ticket.title}")
          end
        end
      end

      # https://github.com/zammad/zammad/issues/3105
      context 'when merge actions triggers exist', :performs_jobs do
        before do
          ticket && target_ticket
          merged_into_trigger && received_merge_trigger && update_trigger

          allow_any_instance_of(described_class).to receive(:perform_changes) do |ticket, trigger|
            log << { ticket: ticket.id, trigger: trigger.id }
          end

          perform_enqueued_jobs do
            ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          end
        end

        let(:merged_into_trigger)    { create(:trigger, :conditionable, condition_ticket_action: 'update.merged_into') }
        let(:received_merge_trigger) { create(:trigger, :conditionable, condition_ticket_action: 'update.received_merge') }
        let(:update_trigger)         { create(:trigger, :conditionable, condition_ticket_action: 'update') }

        let(:log) { [] }

        it 'merge_into triggered with source ticket' do
          expect(log).to include({ ticket: ticket.id, trigger: merged_into_trigger.id })
        end

        it 'received_merge not triggered with source ticket' do
          expect(log).not_to include({ ticket: ticket.id, trigger: received_merge_trigger.id })
        end

        it 'update not triggered with source ticket' do
          expect(log).not_to include({ ticket: ticket.id, trigger: update_trigger.id })
        end

        it 'merge_into not triggered with target ticket' do
          expect(log).not_to include({ ticket: target_ticket.id, trigger: merged_into_trigger.id })
        end

        it 'received_merge triggered with target ticket' do
          expect(log).to include({ ticket: target_ticket.id, trigger: received_merge_trigger.id })
        end

        it 'update not triggered with target ticket' do
          expect(log).not_to include({ ticket: target_ticket.id, trigger: update_trigger.id })
        end
      end

      # https://github.com/zammad/zammad/issues/3105
      context 'when user has notifications enabled', :performs_jobs do
        before do
          user

          allow(OnlineNotification).to receive(:add) do |**args|
            next if args[:object] != 'Ticket'

            log << { type: :online, event: args[:type], ticket_id: args[:o_id], user_id: args[:user_id] }
          end

          allow(NotificationFactory::Mailer).to receive(:notification) do |**args|
            log << { type: :email, event: args[:template], ticket_id: args[:objects][:ticket].id, user_id: args[:user].id }
          end

          perform_enqueued_jobs do
            ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          end
        end

        let(:user) { create(:agent, :preferencable, notification_group_ids: [ticket, target_ticket].map(&:group_id), groups: [ticket, target_ticket].map(&:group)) }
        let(:log)  { [] }

        it 'merge_into notification sent with source ticket' do
          expect(log).to include({ type: :online, event: 'update.merged_into', ticket_id: ticket.id, user_id: user.id })
        end

        it 'received_merge notification not sent with source ticket' do
          expect(log).not_to include({ type: :online, event: 'update.received_merge', ticket_id: ticket.id, user_id: user.id })
        end

        it 'update notification not sent with source ticket' do
          expect(log).not_to include({ type: :online, event: 'update', ticket_id: ticket.id, user_id: user.id })
        end

        it 'merge_into notification not sent with target ticket' do
          expect(log).not_to include({ type: :online, event: 'update.merged_into', ticket_id: target_ticket.id, user_id: user.id })
        end

        it 'received_merge notification sent with target ticket' do
          expect(log).to include({ type: :online, event: 'update.received_merge', ticket_id: target_ticket.id, user_id: user.id })
        end

        it 'update notification not sent with target ticket' do
          expect(log).not_to include({ type: :online, event: 'update', ticket_id: target_ticket.id, user_id: user.id })
        end

        it 'merge_into email sent with source ticket' do
          expect(log).to include({ type: :email, event: 'ticket_update_merged_into', ticket_id: ticket.id, user_id: user.id })
        end

        it 'received_merge email not sent with source ticket' do
          expect(log).not_to include({ type: :email, event: 'ticket_update_received_merge', ticket_id: ticket.id, user_id: user.id })
        end

        it 'update email not sent with source ticket' do
          expect(log).not_to include({ type: :email, event: 'ticket_update', ticket_id: ticket.id, user_id: user.id })
        end

        it 'merge_into email not sent with target ticket' do
          expect(log).not_to include({ type: :email, event: 'ticket_update_merged_into', ticket_id: target_ticket.id, user_id: user.id })
        end

        it 'received_merge email sent with target ticket' do
          expect(log).to include({ type: :email, event: 'ticket_update_received_merge', ticket_id: target_ticket.id, user_id: user.id })
        end

        it 'update email not sent with target ticket' do
          expect(log).not_to include({ type: :email, event: 'ticket_update', ticket_id: target_ticket.id, user_id: user.id })
        end
      end

      # https://github.com/zammad/zammad/issues/3105
      context 'when sending notification email correct template', :performs_jobs do
        before do
          user

          allow(NotificationFactory::Mailer).to receive(:send) do |**args|
            log << args[:subject]
          end

          perform_enqueued_jobs do
            ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          end
        end

        let(:user) { create(:agent, :preferencable, notification_group_ids: [ticket, target_ticket].map(&:group_id), groups: [ticket, target_ticket].map(&:group)) }
        let(:log)  { [] }

        it 'is used for merged_into' do
          expect(log).to include(start_with("Ticket (#{ticket.title}) was merged into another ticket"))
        end

        it 'is used for received_merge' do
          expect(log).to include(start_with("Another ticket was merged into ticket (#{target_ticket.title})"))
        end
      end

      context 'ApplicationHandleInfo context' do
        it 'gets switched to "merge"' do
          allow(ApplicationHandleInfo).to receive('context=')
          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)
          expect(ApplicationHandleInfo).to have_received('context=').with('merge').at_least(1)
        end

        it 'reverts back to default' do
          allow(ApplicationHandleInfo).to receive('context=')
          ticket.merge_to(ticket_id: target_ticket.id, user_id: 1)

          expect(ApplicationHandleInfo.context).not_to eq 'merge'
        end
      end
    end

    describe '#perform_changes' do
      before do
        stub_const('PERFORMABLE_STRUCT', Struct.new(:id, :perform, keyword_init: true))
      end

      # a `performable` can be a Trigger or a Job
      # we use DuckTyping and expect that a performable
      # implements the following interface
      let(:performable) do
        PERFORMABLE_STRUCT.new(id: 1, perform: perform)
      end

      # Regression test for https://github.com/zammad/zammad/issues/2001
      describe 'argument handling' do
        let(:perform) do
          {
            'notification.email' => {
              body:      "Hello \#{ticket.customer.firstname} \#{ticket.customer.lastname},",
              recipient: %w[article_last_sender ticket_owner ticket_customer ticket_agents],
              subject:   "Autoclose (\#{ticket.title})"
            }
          }
        end

        it 'does not mutate contents of "perform" hash' do
          expect { ticket.perform_changes(performable, 'trigger', {}, 1) }
            .not_to change { perform }
        end
      end

      context 'with "ticket.state_id" key in "perform" hash' do
        let(:perform) do
          {
            'ticket.state_id' => {
              'value' => Ticket::State.lookup(name: 'closed').id
            }
          }
        end

        it 'changes #state to specified value' do
          expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }
            .to change { ticket.reload.state.name }.to('closed')
        end
      end

      # Test for backwards compatibility after PR https://github.com/zammad/zammad/pull/2862
      context 'with "pending_time" => { "value": DATE } in "perform" hash' do
        let(:perform) do
          {
            'ticket.state_id'     => {
              'value' => Ticket::State.lookup(name: 'pending reminder').id.to_s
            },
            'ticket.pending_time' => {
              'value' => timestamp,
            },
          }
        end

        let(:timestamp) { Time.zone.now }

        it 'changes pending date to given date' do
          freeze_time do
            expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }
              .to change(ticket, :pending_time).to(be_within(1.minute).of(timestamp))
          end
        end
      end

      # Test for PR https://github.com/zammad/zammad/pull/2862
      context 'with "pending_time" => { "operator": "relative" } in "perform" hash' do
        shared_examples 'verify' do
          it 'verify relative pending time rule' do
            freeze_time do
              interval = relative_value.send(relative_range).from_now

              expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }
                .to change(ticket, :pending_time).to(be_within(1.minute).of(interval))
            end
          end
        end

        let(:perform) do
          {
            'ticket.state_id'     => {
              'value' => Ticket::State.lookup(name: 'pending reminder').id.to_s
            },
            'ticket.pending_time' => {
              'operator' => 'relative',
              'value'    => relative_value,
              'range'    => relative_range_config
            },
          }
        end

        let(:relative_range_config) { relative_range.to_s.singularize }

        context 'and value in days' do
          let(:relative_value) { 2 }
          let(:relative_range) { :days }

          include_examples 'verify'
        end

        context 'and value in minutes' do
          let(:relative_value) { 60 }
          let(:relative_range) { :minutes }

          include_examples 'verify'
        end
      end

      context 'with "ticket.action" => { "value" => "delete" } in "perform" hash' do
        let(:perform) do
          {
            'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s },
            'ticket.action'   => { 'value' => 'delete' },
          }
        end

        it 'performs a ticket deletion on a ticket' do
          expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }
            .to change(ticket, :destroyed?).to(true)
        end
      end

      context 'with a "notification.email" trigger' do
        # Regression test for https://github.com/zammad/zammad/issues/1543
        #
        # If a new article fires an email notification trigger,
        # and then another article is added to the same ticket
        # before that trigger is performed,
        # the email template's 'article' var should refer to the originating article,
        # not the newest one.
        #
        # (This occurs whenever one action fires multiple email notification triggers.)
        context 'when two articles are created before the trigger fires once (race condition)' do
          let!(:article) { create(:ticket_article, ticket: ticket) }
          let!(:new_article) { create(:ticket_article, ticket: ticket) }

          let(:trigger) do
            build(:trigger,
                  perform: {
                    'notification.email' => {
                      body:      '',
                      recipient: 'ticket_customer',
                      subject:   ''
                    }
                  })
          end

          # required by Ticket#perform_changes for email notifications
          before { article.ticket.group.update(email_address: create(:email_address)) }

          it 'passes the first article to NotificationFactory::Mailer' do
            expect(NotificationFactory::Mailer)
              .to receive(:template)
              .with(hash_including(objects: { ticket: ticket, article: article }))
              .at_least(:once)
              .and_call_original

            expect(NotificationFactory::Mailer)
              .not_to receive(:template)
              .with(hash_including(objects: { ticket: ticket, article: new_article }))

            ticket.perform_changes(trigger, 'trigger', { article_id: article.id }, 1)
          end
        end
      end

      context 'with a notification trigger' do
        # https://github.com/zammad/zammad/issues/2782
        #
        # Notification triggers should log notification as private or public
        # according to given configuration
        let(:user) { create(:admin, mobile: '+37061010000') }

        before { ticket.group.users << user }

        let(:perform) do
          {
            notification_key => {
              body:      'Old programmers never die. They just branch to a new address.',
              recipient: 'ticket_agents',
              subject:   'Old programmers never die. They just branch to a new address.'
            }
          }.deep_merge(additional_options).deep_stringify_keys
        end

        let(:notification_key) { "notification.#{notification_type}" }

        shared_examples 'verify log visibility status' do
          shared_examples 'notification trigger' do
            it 'adds Ticket::Article' do
              expect { ticket.perform_changes(performable, 'trigger', ticket, user) }
                .to change { ticket.articles.count }.by(1)
            end

            it 'new Ticket::Article visibility reflects setting' do
              ticket.perform_changes(performable, 'trigger', ticket, User.first)
              new_article = ticket.articles.reload.last
              expect(new_article.internal).to be target_internal_value
            end
          end

          context 'when set to private' do
            let(:additional_options) do
              {
                notification_key => {
                  internal: true
                }
              }
            end

            let(:target_internal_value) { true }

            it_behaves_like 'notification trigger'
          end

          context 'when set to internal' do
            let(:additional_options) do
              {
                notification_key => {
                  internal: false
                }
              }
            end

            let(:target_internal_value) { false }

            it_behaves_like 'notification trigger'
          end

          context 'when no selection was made' do # ensure previously created triggers default to public
            let(:additional_options) do
              {}
            end

            let(:target_internal_value) { false }

            it_behaves_like 'notification trigger'
          end
        end

        context 'dispatching email' do
          let(:notification_type) { :email }

          include_examples 'verify log visibility status'
        end

        shared_examples 'add a new article' do
          it 'adds a new article' do
            expect { ticket.perform_changes(performable, 'trigger', ticket, user) }
              .to change { ticket.articles.count }.by(1)
          end
        end

        shared_examples 'add attachment to new article' do
          include_examples 'add a new article'

          it 'adds attachment to the new article' do
            ticket.perform_changes(performable, 'trigger', ticket, user)
            article = ticket.articles.last

            expect(article.type.name).to eq('email')
            expect(article.sender.name).to eq('System')
            expect(article.attachments.count).to eq(1)
            expect(article.attachments[0].filename).to eq('some_file.pdf')
            expect(article.attachments[0].preferences['Content-ID']).to eq('image/pdf@01CAB192.K8H512Y9')
          end
        end

        shared_examples 'does not add attachment to new article' do
          include_examples 'add a new article'

          it 'does not add attachment to the new article' do
            ticket.perform_changes(performable, 'trigger', ticket, user)
            article = ticket.articles.last

            expect(article.type.name).to eq('email')
            expect(article.sender.name).to eq('System')
            expect(article.attachments.count).to eq(0)
          end
        end

        context 'dispatching email with include attachment present' do
          let(:notification_type) { :email }
          let(:additional_options) do
            {
              notification_key => {
                include_attachments: 'true'
              }
            }
          end

          context 'when ticket has an attachment' do

            before do
              UserInfo.current_user_id = 1
              ticket_article = create(:ticket_article, ticket: ticket)

              create(:store,
                     object:      'Ticket::Article',
                     o_id:        ticket_article.id,
                     data:        'dGVzdCAxMjM=',
                     filename:    'some_file.pdf',
                     preferences: {
                       'Content-Type': 'image/pdf',
                       'Content-ID':   'image/pdf@01CAB192.K8H512Y9',
                     })
            end

            include_examples 'add attachment to new article'
          end

          context 'when ticket does not have an attachment' do

            include_examples 'does not add attachment to new article'
          end
        end

        context 'dispatching email with include attachment not present' do
          let(:notification_type) { :email }
          let(:additional_options) do
            {
              notification_key => {
                include_attachments: 'false'
              }
            }
          end

          context 'when ticket has an attachment' do

            before do
              UserInfo.current_user_id = 1
              ticket_article = create(:ticket_article, ticket: ticket)

              create(:store,
                     object:      'Ticket::Article',
                     o_id:        ticket_article.id,
                     data:        'dGVzdCAxMjM=',
                     filename:    'some_file.pdf',
                     preferences: {
                       'Content-Type': 'image/pdf',
                       'Content-ID':   'image/pdf@01CAB192.K8H512Y9',
                     })
            end

            include_examples 'does not add attachment to new article'
          end

          context 'when ticket does not have an attachment' do

            include_examples 'does not add attachment to new article'
          end
        end

        context 'dispatching SMS' do
          let(:notification_type) { :sms }

          before { create(:channel, area: 'Sms::Notification') }

          include_examples 'verify log visibility status'
        end
      end

      context 'with a "notification.webhook" trigger', performs_jobs: true do
        let(:webhook) { create(:webhook, endpoint: 'http://api.example.com/webhook', signature_token: '53CR3t') }
        let(:trigger) do
          create(:trigger,
                 perform: {
                   'notification.webhook' => { 'webhook_id' => webhook.id }
                 })
        end

        it 'schedules the webhooks notification job' do
          expect { ticket.perform_changes(trigger, 'trigger', {}, 1) }.to have_enqueued_job(TriggerWebhookJob).with(trigger, ticket, nil)
        end
      end

      context 'Allow placeholders in trigger perform actions for ticket/custom attributes #4216' do
        let(:customer) { create(:customer, mobile: '+491907655431') }
        let(:ticket) { create(:ticket, customer: customer) }

        let(:perform) do
          {
            'ticket.title' => {
              'value' => ticket.customer.mobile.to_s,
            }
          }
        end

        it 'does replace custom fields in trigger' do
          ticket.perform_changes(performable, 'trigger', ticket, User.first)
          expect(ticket.reload.title).to eq(customer.mobile)
        end
      end
    end

    describe '#trigger_based_notification?' do
      let(:ticket) { create(:ticket) }

      context 'with a normal user' do
        let(:customer) { create(:customer) }

        it 'send trigger base notification' do
          expect(ticket.send(:trigger_based_notification?, customer)).to be(true)
        end
      end

      context 'with a permanent failed user' do

        let(:failed_date) { 1.second.ago }

        let(:customer) do
          user = create(:customer)
          user.preferences.merge!(mail_delivery_failed: true, mail_delivery_failed_data: failed_date)
          user.save!
          user
        end

        it 'send no trigger base notification' do
          expect(ticket.send(:trigger_based_notification?, customer)).to be(false)
        end

        context 'with failed date 61 days ago' do

          let(:failed_date) { 61.days.ago }

          it 'send trigger base notification' do
            expect(ticket.send(:trigger_based_notification?, customer)).to be(true)
          end
        end
      end
    end

    describe '#subject_build' do
      context 'with default "ticket_hook_position" setting ("right")' do
        it 'returns the given string followed by a ticket reference (of the form "[Ticket#123]")' do
          expect(ticket.subject_build('foo'))
            .to eq("foo [Ticket##{ticket.number}]")
        end

        context 'and a non-default value for the "ticket_hook" setting' do
          before { Setting.set('ticket_hook', 'bar baz') }

          it 'replaces "Ticket#" with the new ticket hook' do
            expect(ticket.subject_build('foo'))
              .to eq("foo [bar baz#{ticket.number}]")
          end
        end

        context 'and a non-default value for the "ticket_hook_divider" setting' do
          before { Setting.set('ticket_hook_divider', ': ') }

          it 'inserts the new ticket hook divider between "Ticket#" and the ticket number' do
            expect(ticket.subject_build('foo'))
              .to eq("foo [Ticket#: #{ticket.number}]")
          end
        end

        context 'when the given string already contains a ticket reference, but in the wrong place' do
          it 'moves the ticket reference to the end' do
            expect(ticket.subject_build("[Ticket##{ticket.number}] foo"))
              .to eq("foo [Ticket##{ticket.number}]")
          end
        end

        context 'when the given string already contains an alternately formatted ticket reference' do
          it 'reformats the ticket reference' do
            expect(ticket.subject_build("foo [Ticket#: #{ticket.number}]"))
              .to eq("foo [Ticket##{ticket.number}]")
          end
        end
      end

      context 'with alternate "ticket_hook_position" setting ("left")' do
        before { Setting.set('ticket_hook_position', 'left') }

        it 'returns a ticket reference (of the form "[Ticket#123]") followed by the given string' do
          expect(ticket.subject_build('foo'))
            .to eq("[Ticket##{ticket.number}] foo")
        end

        context 'and a non-default value for the "ticket_hook" setting' do
          before { Setting.set('ticket_hook', 'bar baz') }

          it 'replaces "Ticket#" with the new ticket hook' do
            expect(ticket.subject_build('foo'))
              .to eq("[bar baz#{ticket.number}] foo")
          end
        end

        context 'and a non-default value for the "ticket_hook_divider" setting' do
          before { Setting.set('ticket_hook_divider', ': ') }

          it 'inserts the new ticket hook divider between "Ticket#" and the ticket number' do
            expect(ticket.subject_build('foo'))
              .to eq("[Ticket#: #{ticket.number}] foo")
          end
        end

        context 'when the given string already contains a ticket reference, but in the wrong place' do
          it 'moves the ticket reference to the start' do
            expect(ticket.subject_build("foo [Ticket##{ticket.number}]"))
              .to eq("[Ticket##{ticket.number}] foo")
          end
        end

        context 'when the given string already contains an alternately formatted ticket reference' do
          it 'reformats the ticket reference' do
            expect(ticket.subject_build("[Ticket#: #{ticket.number}] foo"))
              .to eq("[Ticket##{ticket.number}] foo")
          end
        end
      end
    end

    describe '#last_original_update_at' do
      let(:result) { ticket.last_original_update_at }

      it 'returns initial customer enquiry time when customer contacted repeatedly' do
        ticket

        target = create(:ticket_article, :inbound_email, ticket: ticket)
        travel 10.minutes
        create(:ticket_article, :inbound_email, ticket: ticket)

        expect(result).to eq target.created_at
      end

      it 'returns agent contact time when customer did not respond to agent reach out' do
        ticket
        create(:ticket_article, :outbound_email, ticket: ticket)

        expect(result).to eq ticket.last_contact_agent_at
      end

      it 'returns nil if no customer response' do
        ticket
        expect(result).to be_nil
      end

      context 'with customer enquiry and agent response' do
        before do
          ticket
          create(:ticket_article, :inbound_email, ticket: ticket)
          travel 10.minutes
          create(:ticket_article, :outbound_email, ticket: ticket)
          travel 10.minutes
        end

        it 'returns last customer enquiry time when agent did not respond yet' do
          target = create(:ticket_article, :inbound_email, ticket: ticket)

          expect(result).to eq target.created_at
        end

        it 'returns agent response time when agent responded to customer enquiry' do
          expect(result).to eq ticket.last_contact_agent_at
        end
      end
    end

    describe '#param_cleanup' do
      it 'does only remove parameters which are invalid and not the complete params hash if one element is invalid (#3743)' do
        expect(described_class.param_cleanup({ state_id: 3, customer_id: 'guess:1234' }, true, false, false)).to eq({ 'state_id' => 3 })
      end
    end
  end

  describe 'Attributes:' do
    describe '#owner' do
      let(:original_owner) { create(:agent, groups: [ticket.group]) }

      before { ticket.update(owner: original_owner) }

      context 'when assigned directly' do
        context 'to an active agent belonging to ticket.group' do
          let(:agent) { create(:agent, groups: [ticket.group]) }

          it 'can be set' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(agent)
          end
        end

        context 'to an agent not belonging to ticket.group' do
          let(:agent)       { create(:agent, groups: [other_group]) }
          let(:other_group) { create(:group) }

          it 'resets to default user (id: 1) instead' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'to an inactive agent' do
          let(:agent) { create(:agent, groups: [ticket.group], active: false) }

          it 'resets to default user (id: 1) instead' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'to a non-agent' do
          let(:agent) { create(:customer, groups: [ticket.group]) }

          it 'resets to default user (id: 1) instead' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end
      end

      context 'when the ticket is updated for any other reason' do
        context 'if original owner is still an active agent belonging to ticket.group' do
          it 'does not change' do
            expect { create(:ticket_article, ticket: ticket) }
              .not_to change { ticket.reload.owner }
          end
        end

        context 'if original owner has left ticket.group' do
          before { original_owner.groups = [] }

          it 'resets to default user (id: 1)' do
            expect { create(:ticket_article, ticket: ticket) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'if original owner has become inactive' do
          before { original_owner.update(active: false) }

          it 'resets to default user (id: 1)' do
            expect { create(:ticket_article, ticket: ticket) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'if original owner has lost agent status' do
          before { original_owner.roles = [create(:role)] }

          it 'resets to default user (id: 1)' do
            Rails.cache.clear
            expect { create(:ticket_article, ticket: ticket) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'when the Ticket is closed' do

          before do
            ticket.update!(state: Ticket::State.lookup(name: 'closed'))
          end

          context 'if original owner is still an active agent belonging to ticket.group' do
            it 'does not change' do
              expect { create(:ticket_article, ticket: ticket) }
                .not_to change { ticket.reload.owner }
            end
          end

          context 'if original owner has left ticket.group' do
            before { original_owner.groups = [] }

            it 'does not change' do
              expect { create(:ticket_article, ticket: ticket) }
                .not_to change { ticket.reload.owner }
            end
          end

          context 'if original owner has become inactive' do
            before { original_owner.update(active: false) }

            it 'does not change' do
              expect { create(:ticket_article, ticket: ticket) }
                .not_to change { ticket.reload.owner }
            end
          end

          context 'if original owner has lost agent status' do
            before { original_owner.roles = [create(:role)] }

            it 'does not change' do
              expect { create(:ticket_article, ticket: ticket) }
                .not_to change { ticket.reload.owner }
            end
          end
        end
      end
    end

    describe '#state' do
      context 'when originally "new" (default)' do
        context 'and a customer article is added' do
          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Customer') }

          it 'stays "new"' do
            expect { article }
              .not_to change { ticket.state.name }.from('new')
          end
        end

        context 'and a non-customer article is added' do
          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'switches to "open"' do
            expect { article }
              .to change { ticket.reload.state.name }.from('new').to('open')
          end
        end
      end

      context 'when originally "closed"' do
        before { ticket.update(state: Ticket::State.find_by(name: 'closed')) }

        context 'when a non-customer article is added' do
          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'stays "closed"' do
            expect { article }.not_to change { ticket.reload.state.name }
          end
        end
      end
    end

    describe '#pending_time' do
      subject(:ticket) { create(:ticket, pending_time: 2.days.from_now) }

      context 'when #state is updated to any non-"pending" value' do
        it 'is reset to nil' do
          expect { ticket.update!(state: Ticket::State.lookup(name: 'open')) }
            .to change(ticket, :pending_time).to(nil)
        end
      end

      # Regression test for commit 92f227786f298bad1ccaf92d4478a7062ea6a49f
      context 'when #state is updated to nil (violating DB NOT NULL constraint)' do
        it 'does not prematurely raise within the callback (#reset_pending_time)' do
          expect { ticket.update!(state: nil) }
            .to raise_error(ActiveRecord::StatementInvalid)
        end
      end
    end

    describe '#escalation_at' do
      before { freeze_time } # freeze time

      let(:sla)      { create(:sla, calendar: calendar, first_response_time: 60, response_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.escalation_at).to be_nil
        end
      end

      context 'with an SLA in the system' do
        before { sla } # create sla

        it 'is set based on SLA’s #first_response_time' do
          expect(ticket.reload.escalation_at.to_i)
            .to eq(1.hour.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket } # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'is updated based on the SLA’s #close_escalation_at' do
            travel(1.minute) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

            expect { article }
              .to change { ticket.reload.escalation_at }
              .to(ticket.reload.close_escalation_at)
          end

          context 'when new #update_time is later than original #solution_time' do
            it 'is updated based on the original #solution_time' do
              travel(2.hours) # time is frozen: if we don't travel forward, pre- and post-update values will be the same

              expect { article }
                .to change { ticket.reload.escalation_at }
                .to(4.hours.after(ticket.created_at))
            end
          end
        end
      end

      context 'when updated after an SLA has been added to the system' do
        before do
          ticket  # create ticket
          sla     # create sla
        end

        it 'is updated based on the new SLA’s #first_response_time' do
          expect { ticket.save! }
            .to change { ticket.reload.escalation_at.to_i }.from(0).to(1.hour.from_now.to_i)
        end
      end

      context 'when updated after all SLAs have been removed from the system' do
        before do
          sla     # create sla
          ticket  # create ticket
          sla.destroy
        end

        it 'is set to nil' do
          expect { ticket.save! }
            .to change { ticket.reload.escalation_at }.to(nil)
        end
      end

      context 'when within last (relative)' do
        let(:first_response_time) { 5 }
        let(:sla)                 { create(:sla, calendar: calendar, first_response_time: first_response_time) }
        let(:within_condition) do
          { 'ticket.escalation_at'=>{ 'operator' => 'within last (relative)', 'value' => '30', 'range' => 'minute' } }
        end

        before do
          sla

          travel_to '2020-11-05 11:37:00'

          ticket = create(:ticket)
          create(:ticket_article, :inbound_email, ticket: ticket)

          travel_to '2020-11-05 11:50:00'
        end

        context 'when in range' do
          it 'does find the ticket' do
            count, _tickets = described_class.selectors(within_condition, limit: 2_000, execution_time: true)
            expect(count).to eq(1)
          end
        end

        context 'when out of range' do
          let(:first_response_time) { 500 }

          it 'does not find the ticket' do
            count, _tickets = described_class.selectors(within_condition, limit: 2_000, execution_time: true)
            expect(count).to eq(0)
          end
        end
      end

      context 'when till (relative)' do
        let(:first_response_time) { 5 }
        let(:sla)                 { create(:sla, calendar: calendar, first_response_time: first_response_time) }
        let(:condition) do
          { 'ticket.escalation_at'=>{ 'operator' => 'till (relative)', 'value' => '30', 'range' => 'minute' } }
        end

        before do
          sla

          travel_to '2020-11-05 11:37:00'

          ticket = create(:ticket)
          create(:ticket_article, :inbound_email, ticket: ticket)

          travel_to '2020-11-05 11:50:00'
        end

        context 'when in range' do
          it 'does find the ticket' do
            count, _tickets = described_class.selectors(condition, limit: 2_000, execution_time: true)
            expect(count).to eq(1)
          end
        end

        context 'when out of range' do
          let(:first_response_time) { 500 }

          it 'does not find the ticket' do
            count, _tickets = described_class.selectors(condition, limit: 2_000, execution_time: true)
            expect(count).to eq(0)
          end
        end
      end

      context 'when from (relative)' do
        let(:first_response_time) { 5 }
        let(:sla)                 { create(:sla, calendar: calendar, first_response_time: first_response_time) }
        let(:condition) do
          { 'ticket.escalation_at'=>{ 'operator' => 'from (relative)', 'value' => '30', 'range' => 'minute' } }
        end

        before do
          sla

          travel_to '2020-11-05 11:37:00'

          ticket = create(:ticket)
          create(:ticket_article, :inbound_email, ticket: ticket)
        end

        context 'when in range' do
          it 'does find the ticket' do
            travel_to '2020-11-05 11:50:00'
            count, _tickets = described_class.selectors(condition, limit: 2_000, execution_time: true)
            expect(count).to eq(1)
          end
        end

        context 'when out of range' do
          let(:first_response_time) { 5 }

          it 'does not find the ticket' do
            travel_to '2020-11-05 13:50:00'
            count, _tickets = described_class.selectors(condition, limit: 2_000, execution_time: true)
            expect(count).to eq(0)
          end
        end
      end

      context 'when within next (relative)' do
        let(:first_response_time) { 5 }
        let(:sla)                 { create(:sla, calendar: calendar, first_response_time: first_response_time) }
        let(:within_condition) do
          { 'ticket.escalation_at'=>{ 'operator' => 'within next (relative)', 'value' => '30', 'range' => 'minute' } }
        end

        before do
          sla

          travel_to '2020-11-05 11:50:00'

          ticket = create(:ticket)
          create(:ticket_article, :inbound_email, ticket: ticket)

          travel_to '2020-11-05 11:37:00'
        end

        context 'when in range' do
          it 'does find the ticket' do
            count, _tickets = described_class.selectors(within_condition, limit: 2_000, execution_time: true)
            expect(count).to eq(1)
          end
        end

        context 'when out of range' do
          let(:first_response_time) { 500 }

          it 'does not find the ticket' do
            count, _tickets = described_class.selectors(within_condition, limit: 2_000, execution_time: true)
            expect(count).to eq(0)
          end
        end
      end
    end

    describe '#first_response_escalation_at' do
      before { freeze_time } # freeze time

      let(:sla)      { create(:sla, calendar: calendar, first_response_time: 60, response_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.first_response_escalation_at).to be_nil
        end
      end

      context 'with an SLA in the system' do
        before { sla } # create sla

        it 'is set based on SLA’s #first_response_time' do
          expect(ticket.reload.first_response_escalation_at.to_i)
            .to eq(1.hour.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket } # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'is cleared' do
            expect { article }.to change { ticket.reload.first_response_escalation_at }.to(nil)
          end
        end
      end
    end

    describe '#update_escalation_at' do
      before { freeze_time } # freeze time

      let(:sla)      { create(:sla, calendar: calendar, first_response_time: 60, response_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.update_escalation_at).to be_nil
        end
      end

      context 'with an SLA in the system' do
        before { sla } # create sla

        it 'is set based on SLA’s #update_time' do
          travel 1.minute
          create(:ticket_article, ticket: ticket, sender_name: 'Customer')

          expect(ticket.reload.update_escalation_at.to_i)
            .to eq(3.hours.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket } # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'is updated based on the SLA’s #update_time' do
            create(:ticket_article, ticket: ticket, sender_name: 'Customer')
            travel(1.minute)

            expect { article }
              .to change { ticket.reload.update_escalation_at }
              .to(nil)
          end
        end
      end
    end

    describe '#close_escalation_at' do
      before { freeze_time } # freeze time

      let(:sla)      { create(:sla, calendar: calendar, first_response_time: 60, response_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.close_escalation_at).to be_nil
        end
      end

      context 'with an SLA in the system' do
        before { sla } # create sla

        it 'is set based on SLA’s #solution_time' do
          expect(ticket.reload.close_escalation_at.to_i)
            .to eq(4.hours.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket } # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'does not change' do
            expect { article }.not_to change(ticket, :close_escalation_at)
          end
        end
      end
    end
  end

  describe '.search' do

    shared_examples 'search permissions' do
      let(:group) { create(:group) }

      before do
        ticket
      end

      shared_examples 'permitted' do
        it 'finds Ticket' do
          expect(described_class.search(query: ticket.number, current_user: current_user).count).to eq(1)
        end
      end

      shared_examples 'no permission' do
        it "doesn't find Ticket" do
          expect(described_class.search(query: ticket.number, current_user: current_user)).to be_blank
        end
      end

      context 'Agent with Group access' do

        let(:ticket) do
          ticket = create(:ticket, group: group)
          create(:ticket_article, ticket: ticket)
          ticket
        end

        let(:current_user) { create(:agent, groups: [group]) }

        it_behaves_like 'permitted'
      end

      context 'when Agent is Customer of Ticket' do

        let(:ticket) do
          ticket = create(:ticket, customer: current_user)
          create(:ticket_article, ticket: ticket)
          ticket
        end

        let(:current_user) { create(:agent_and_customer) }

        it_behaves_like 'permitted'
      end

      context 'for Organization access' do

        let(:ticket) do
          ticket = create(:ticket, customer: customer)
          create(:ticket_article, ticket: ticket)
          ticket
        end

        let(:customer) { create(:customer, organization: organization) }

        context 'when Organization is shared' do
          let(:organization) { create(:organization, shared: true) }

          context 'for unrelated Agent' do
            let(:current_user) { create(:agent) }

            it_behaves_like 'no permission'
          end

          context 'for Agent in same Organization' do
            let(:current_user) { create(:agent_and_customer, organization: organization) }

            it_behaves_like 'permitted'
          end

          context 'for Customer of Ticket' do
            let(:current_user) { customer }

            it_behaves_like 'permitted'
          end
        end

        context 'when Organization is not shared' do
          let(:organization) { create(:organization, shared: false) }

          context 'for unrelated Agent' do
            let(:current_user) { create(:agent) }

            it_behaves_like 'no permission'
          end

          context 'for Agent in same Organization' do
            let(:current_user) { create(:agent_and_customer, organization: organization) }

            it_behaves_like 'no permission'
          end

          context 'for Customer of Ticket' do
            let(:current_user) { customer }

            it_behaves_like 'permitted'
          end
        end
      end
    end

    context 'with searchindex', searchindex: true do

      include_examples 'search permissions' do
        before do
          searchindex_model_reload([::Ticket])
        end
      end
    end

    context 'without searchindex' do
      before do
        Setting.set('es_url', nil)
      end

      include_examples 'search permissions'
    end
  end

  describe 'Callbacks & Observers -' do
    describe 'NULL byte handling (via ChecksAttributeValuesAndLength concern):' do
      it 'removes them from title on creation, if necessary (postgres doesn’t like them)' do
        expect { create(:ticket, title: "some title \u0000 123") }
          .not_to raise_error
      end
    end

    describe 'XSS protection:' do
      subject(:ticket) { create(:ticket, title: title) }

      let(:title) { 'test 123 <script type="text/javascript">alert("XSS!");</script>' }

      it 'does not sanitize title' do
        expect(ticket.title).to eq(title)
      end
    end

    describe 'Cti::CallerId syncing:', performs_jobs: true do
      subject(:ticket) { build(:ticket) }

      before { allow(Cti::CallerId).to receive(:build) }

      it 'adds numbers in article bodies (via Cti::CallerId.build)' do
        expect(Cti::CallerId).to receive(:build).with(ticket)

        ticket.save
        perform_enqueued_jobs commit_transaction: true
      end
    end

    describe 'Touching associations on update:' do
      subject(:ticket) { create(:ticket, customer: customer) }

      let(:customer) { create(:customer, organization: organization) }
      let(:organization)       { create(:organization) }
      let(:other_customer)     { create(:customer, organization: other_organization) }
      let(:other_organization) { create(:organization) }

      context 'on creation' do
        it 'touches its customer and his organization' do
          expect { ticket }
            .to change { customer.reload.updated_at }
            .and change { organization.reload.updated_at }
        end
      end

      context 'on destruction' do
        before { ticket }

        it 'touches its customer and his organization' do
          expect { ticket.destroy }
            .to change { customer.reload.updated_at }
            .and change { organization.reload.updated_at }
        end
      end

      context 'when customer association is changed' do
        it 'touches both old and new customer, and their organizations' do
          expect { ticket.update(customer: other_customer) }
            .to change { customer.reload.updated_at }
            .and change { organization.reload.updated_at }
            .and change { other_customer.reload.updated_at }
            .and change { other_organization.reload.updated_at }
        end
      end
    end

    describe 'Association & attachment management:' do
      it 'deletes all related ActivityStreams on destroy' do
        create_list(:activity_stream, 3, o: ticket)

        expect { ticket.destroy }
          .to change { ActivityStream.exists?(activity_stream_object_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id) }
          .to(false)
      end

      it 'deletes all related Links on destroy' do
        create(:link, from: ticket, to: create(:ticket))
        create(:link, from: create(:ticket), to: ticket)
        create(:link, from: ticket, to: create(:ticket))

        expect { ticket.destroy }
          .to change { Link.where('link_object_source_value = :id OR link_object_target_value = :id', id: ticket.id).any? }
          .to(false)
      end

      it 'deletes all related Articles on destroy' do
        create_list(:ticket_article, 3, ticket: ticket)

        expect { ticket.destroy }
          .to change { Ticket::Article.exists?(ticket: ticket) }
          .to(false)
      end

      it 'deletes all related OnlineNotifications on destroy' do
        create_list(:online_notification, 3, o: ticket)

        expect { ticket.destroy }
          .to change { OnlineNotification.where(object_lookup_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id).any? }
          .to(false)
      end

      it 'deletes all related Tags on destroy' do
        create_list(:tag, 3, o: ticket)

        expect { ticket.destroy }
          .to change { Tag.exists?(tag_object_id: Tag::Object.lookup(name: 'Ticket').id, o_id: ticket.id) }
          .to(false)
      end

      it 'deletes all related Histories on destroy' do
        create_list(:history, 3, o: ticket)

        expect { ticket.destroy }
          .to change { History.exists?(history_object_id: History::Object.lookup(name: 'Ticket').id, o_id: ticket.id) }
          .to(false)
      end

      it 'deletes all related RecentViews on destroy' do
        create_list(:recent_view, 3, o: ticket)

        expect { ticket.destroy }
          .to change { RecentView.exists?(recent_view_object_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id) }
          .to(false)
      end

      it 'destroys all related dependencies' do
        refs_known = { 'Ticket::Article'         => { 'ticket_id'=>1 },
                       'Ticket::TimeAccounting'  => { 'ticket_id'=>1 },
                       'Ticket::SharedDraftZoom' => { 'ticket_id'=>0 },
                       'Ticket::Flag'            => { 'ticket_id'=>1 } }

        ticket     = create(:ticket)
        article    = create(:ticket_article, ticket: ticket)
        accounting = create(:ticket_time_accounting, ticket: ticket)
        flag       = create(:ticket_flag, ticket: ticket)

        refs_ticket = Models.references('Ticket', ticket.id, true)
        expect(refs_ticket).to eq(refs_known)

        ticket.destroy

        expect { ticket.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { article.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { accounting.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { flag.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      context 'when ticket is generated from email (with attachments)' do
        subject(:ticket) { Channel::EmailParser.new.process({}, raw_email).first }

        let(:raw_email) { Rails.root.join('test/data/mail/mail001.box').read }

        it 'adds attachments to the Store{::File,::Provider::DB} tables' do
          expect { ticket }
            .to change(Store, :count).by(2)
            .and change(Store::File, :count).by(2)
            .and change(Store::Provider::DB, :count).by(2)
        end

        context 'and subsequently destroyed' do
          it 'deletes all related attachments' do
            ticket # create ticket

            expect { ticket.destroy }
              .to change(Store, :count).by(-2)
              .and change(Store::File, :count).by(-2)
              .and change(Store::Provider::DB, :count).by(-2)
          end
        end

        context 'and a duplicate ticket is generated from the same email' do
          before { ticket } # create ticket

          let(:duplicate) { Channel::EmailParser.new.process({}, raw_email).first }

          it 'adds duplicate attachments to the Store table only' do
            expect { duplicate }
              .to change(Store, :count).by(2)
              .and not_change(Store::File, :count)
              .and not_change(Store::Provider::DB, :count)
          end

          context 'when only the duplicate ticket is destroyed' do
            it 'deletes only the duplicate attachments' do
              duplicate # create ticket

              expect { duplicate.destroy }
                .to change(Store, :count).by(-2)
                .and not_change(Store::File, :count)
                .and not_change(Store::Provider::DB, :count)
            end

            it 'deletes all related attachments' do
              duplicate.destroy

              expect { ticket.destroy }
                .to change(Store, :count).by(-2)
                .and change(Store::File, :count).by(-2)
                .and change(Store::Provider::DB, :count).by(-2)
            end
          end
        end
      end
    end

    describe 'Ticket lifecycle order-of-operations:', performs_jobs: true do
      subject!(:ticket) { create(:ticket) }

      let!(:agent) { create(:agent, groups: [group]) }
      let(:group) { create(:group) }

      before do
        create(
          :trigger,
          condition: { 'ticket.action' => { 'operator' => 'is', 'value' => 'create' } },
          perform:   { 'ticket.group_id' => { 'value' => group.id } }
        )
      end

      it 'fires triggers before new ticket notifications are sent' do
        expect { TransactionDispatcher.commit }
          .to change { ticket.reload.group }.to(group)

        expect { perform_enqueued_jobs }
          .to change { NotificationFactory::Mailer.already_sent?(ticket, agent, 'email') }.to(1)
      end
    end

    describe 'Ticket has changed attributes:' do
      subject!(:ticket) { create(:ticket) }

      let(:group) { create(:group) }
      let(:condition_field) { nil }

      shared_examples 'updated ticket group with trigger condition' do
        it 'updated ticket group with has changed trigger condition' do
          expect { TransactionDispatcher.commit }.to change { ticket.reload.group }.to(group)
        end
      end

      before do
        create(
          :trigger,
          condition: { "ticket.#{condition_field}" => { 'operator' => 'has changed', 'value' => 'create' } },
          perform:   { 'ticket.group_id' => { 'value' => group.id } }
        )

        ticket.update!(condition_field => Time.zone.now)
      end

      context "when changing 'first_response_at' attribute" do
        let(:condition_field) { 'first_response_at' }

        include_examples 'updated ticket group with trigger condition'
      end

      context "when changing 'close_at' attribute" do
        let(:condition_field) { 'close_at' }

        include_examples 'updated ticket group with trigger condition'
      end

      context "when changing 'last_contact_agent_at' attribute" do
        let(:condition_field) { 'last_contact_agent_at' }

        include_examples 'updated ticket group with trigger condition'
      end

      context "when changing 'last_contact_customer_at' attribute" do
        let(:condition_field) { 'last_contact_customer_at' }

        include_examples 'updated ticket group with trigger condition'
      end

      context "when changing 'last_contact_at' attribute" do
        let(:condition_field) { 'last_contact_at' }

        include_examples 'updated ticket group with trigger condition'
      end
    end
  end

  describe 'Mentions:', sends_notification_emails: true do
    context 'when notifications', performs_jobs: true do
      let(:prefs_matrix_no_mentions) do
        { 'notification_config' =>
                                   { 'matrix' =>
                                                 { 'create'           => { 'criteria' => { 'owned_by_me' => true, 'owned_by_nobody' => true, 'subscribed' => false, 'no' => true }, 'channel' => { 'email' => true, 'online' => true } },
                                                   'update'           => { 'criteria' => { 'owned_by_me' => true, 'owned_by_nobody' => true, 'subscribed' => false, 'no' => true }, 'channel' => { 'email' => true, 'online' => true } },
                                                   'reminder_reached' => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => false, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } },
                                                   'escalation'       => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => false, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } } } } }
      end

      let(:prefs_matrix_only_mentions) do
        { 'notification_config' =>
                                   { 'matrix' =>
                                                 { 'create'           => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => true, 'online' => true } },
                                                   'update'           => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => true, 'online' => true } },
                                                   'reminder_reached' => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } },
                                                   'escalation'       => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } } } } }
      end

      let(:prefs_matrix_only_mentions_groups) do
        { 'notification_config' =>
                                   { 'matrix'    =>
                                                    { 'create'           => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => true, 'online' => true } },
                                                      'update'           => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => true, 'online' => true } },
                                                      'reminder_reached' => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } },
                                                      'escalation'       => { 'criteria' => { 'owned_by_me' => false, 'owned_by_nobody' => false, 'subscribed' => true, 'no' => false }, 'channel' => { 'email' => false, 'online' => false } } },
                                     'group_ids' => [create(:group).id, create(:group).id, create(:group).id] } }
      end

      let(:mention_group)      { create(:group) }
      let(:no_access_group)    { create(:group) }
      let(:user_only_mentions) { create(:agent, groups: [mention_group], preferences: prefs_matrix_only_mentions) }
      let(:user_read_mentions) { create(:agent, groups: [mention_group], preferences: prefs_matrix_only_mentions_groups) }
      let(:user_no_mentions)   { create(:agent, groups: [mention_group], preferences: prefs_matrix_no_mentions) }
      let(:ticket)             { create(:ticket, group: mention_group, owner: user_no_mentions) }

      it 'does inform mention user about the ticket update' do
        create(:mention, mentionable: ticket, user: user_only_mentions)
        create(:mention, mentionable: ticket, user: user_read_mentions)
        create(:mention, mentionable: ticket, user: user_no_mentions)
        perform_enqueued_jobs commit_transaction: true

        check_notification do
          ticket.update(priority: Ticket::Priority.find_by(name: '3 high'))
          perform_enqueued_jobs commit_transaction: true
          sent(
            template: 'ticket_update',
            user:     user_no_mentions,
          )
          sent(
            template: 'ticket_update',
            user:     user_read_mentions,
          )
          sent(
            template: 'ticket_update',
            user:     user_only_mentions,
          )
        end
      end

      it 'does not inform mention user about the ticket update' do
        ticket
        perform_enqueued_jobs commit_transaction: true

        check_notification do
          ticket.update(priority: Ticket::Priority.find_by(name: '3 high'))
          perform_enqueued_jobs commit_transaction: true
          sent(
            template: 'ticket_update',
            user:     user_no_mentions,
          )
          not_sent(
            template: 'ticket_update',
            user:     user_read_mentions,
          )
          not_sent(
            template: 'ticket_update',
            user:     user_only_mentions,
          )
        end
      end

      it 'does inform mention user about ticket creation' do
        check_notification do
          ticket = create(:ticket, owner: user_no_mentions, group: mention_group)
          create(:mention, mentionable: ticket, user: user_read_mentions)
          create(:mention, mentionable: ticket, user: user_only_mentions)
          perform_enqueued_jobs commit_transaction: true
          sent(
            template: 'ticket_create',
            user:     user_no_mentions,
          )
          sent(
            template: 'ticket_create',
            user:     user_read_mentions,
          )
          sent(
            template: 'ticket_create',
            user:     user_only_mentions,
          )
        end
      end

      it 'does not inform mention user about ticket creation' do
        check_notification do
          create(:ticket, owner: user_no_mentions, group: mention_group)
          perform_enqueued_jobs commit_transaction: true
          sent(
            template: 'ticket_create',
            user:     user_no_mentions,
          )
          not_sent(
            template: 'ticket_create',
            user:     user_read_mentions,
          )
          not_sent(
            template: 'ticket_create',
            user:     user_only_mentions,
          )
        end
      end

      it 'does not inform mention user about ticket creation because of no permissions' do
        check_notification do
          ticket = create(:ticket, group: no_access_group)
          create(:mention, mentionable: ticket, user: user_read_mentions)
          create(:mention, mentionable: ticket, user: user_only_mentions)
          perform_enqueued_jobs commit_transaction: true
          not_sent(
            template: 'ticket_create',
            user:     user_read_mentions,
          )
          not_sent(
            template: 'ticket_create',
            user:     user_only_mentions,
          )
        end
      end
    end

    context 'selectors' do
      let(:mention_group) { create(:group) }
      let(:ticket_mentions)  { create(:ticket, group: mention_group) }
      let(:ticket_normal)    { create(:ticket, group: mention_group) }
      let(:user_mentions)    { create(:agent, groups: [mention_group]) }
      let(:user_no_mentions) { create(:agent, groups: [mention_group]) }

      before do
        described_class.destroy_all
        ticket_normal
        user_no_mentions
        create(:mention, mentionable: ticket_mentions, user: user_mentions)
      end

      it 'pre condition is not_set' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'not_set',
            operator:      'is',
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full'))
          .to match_array([1, [ticket_normal].to_a])
      end

      it 'pre condition is not not_set' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'not_set',
            operator:      'is not',
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full'))
          .to match_array([1, [ticket_mentions].to_a])
      end

      it 'pre condition is current_user.id' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'current_user.id',
            operator:      'is',
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full', current_user: user_mentions))
          .to match_array([1, [ticket_mentions].to_a])
      end

      it 'pre condition is not current_user.id' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'current_user.id',
            operator:      'is not',
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full', current_user: user_mentions))
          .to match_array([0, []])
      end

      it 'pre condition is specific' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'specific',
            operator:      'is',
            value:         user_mentions.id
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full'))
          .to match_array([1, [ticket_mentions].to_a])
      end

      it 'pre condition is not specific' do
        condition = {
          'ticket.mention_user_ids' => {
            pre_condition: 'specific',
            operator:      'is not',
            value:         user_mentions.id
          },
        }

        expect(described_class.selectors(condition, limit: 100, access: 'full'))
          .to match_array([0, []])
      end
    end
  end

  describe '.search_index_attribute_lookup_oversized?' do
    subject!(:ticket) { create(:ticket) }

    context 'when payload is ok' do
      let(:current_payload_size) { 3.megabyte }

      it 'return false' do
        expect(ticket.send(:search_index_attribute_lookup_oversized?, current_payload_size)).to be false
      end
    end

    context 'when payload is bigger' do
      let(:current_payload_size) { 350.megabyte }

      it 'return true' do
        expect(ticket.send(:search_index_attribute_lookup_oversized?, current_payload_size)).to be true
      end
    end
  end

  describe '.search_index_attribute_lookup_file_oversized?' do
    subject!(:store) do
      create(:store,
             object:   'SomeObject',
             o_id:     1,
             data:     'a' * ((1024**2) * 2.4), # with 2.4 mb
             filename: 'test.TXT')
    end

    context 'when total payload is ok' do
      let(:current_payload_size) { 200.megabyte }

      it 'return false' do
        expect(ticket.send(:search_index_attribute_lookup_file_oversized?, store, current_payload_size)).to be false
      end
    end

    context 'when total payload is oversized' do
      let(:current_payload_size) { 299.megabyte }

      it 'return true' do
        expect(ticket.send(:search_index_attribute_lookup_file_oversized?, store, current_payload_size)).to be true
      end
    end
  end

  describe '.search_index_attribute_lookup_file_ignored?' do
    context 'when attachment is indexable' do
      subject!(:store_with_indexable_extention) do
        create(:store,
               object:   'SomeObject',
               o_id:     1,
               data:     'some content',
               filename: 'test.TXT')
      end

      it 'return false' do
        expect(ticket.send(:search_index_attribute_lookup_file_ignored?, store_with_indexable_extention)).to be false
      end
    end

    context 'when attachment is no indexable' do
      subject!(:store_without_indexable_extention) do
        create(:store,
               object:   'SomeObject',
               o_id:     1,
               data:     'some content',
               filename: 'test.BIN')
      end

      it 'return true' do
        expect(ticket.send(:search_index_attribute_lookup_file_ignored?, store_without_indexable_extention)).to be true
      end
    end
  end

  describe '.search_index_attribute_lookup' do
    subject!(:ticket) { create(:ticket) }

    let(:search_index_attribute_lookup) do
      article1 = create(:ticket_article, ticket: ticket)
      create(:store,
             object:      'Ticket::Article',
             o_id:        article1.id,
             data:        'some content',
             filename:    'some_file.bin',
             preferences: {
               'Content-Type' => 'text/plain',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article1.id,
             data:        'a' * ((1024**2) * 2.4), # with 2.4 mb
             filename:    'some_file.pdf',
             preferences: {
               'Content-Type' => 'image/pdf',
             })
      create(:store,
             object:      'Ticket::Article',
             o_id:        article1.id,
             data:        'a' * ((1024**2) * 5.8), # with 5,8 mb
             filename:    'some_file.txt',
             preferences: {
               'Content-Type' => 'text/plain',
             })
      create(:ticket_article, ticket: ticket, body: 'a' * ((1024**2) * 1.2)) # body with 1,2 mb
      create(:ticket_article, ticket: ticket)
      ticket.search_index_attribute_lookup
    end

    context 'when es_attachment_max_size_in_mb takes all attachments' do
      before { Setting.set('es_attachment_max_size_in_mb', 15) }

      it 'verify count of articles' do
        expect(search_index_attribute_lookup['article'].count).to eq 3
      end

      it 'verify count of attachments' do
        expect(search_index_attribute_lookup['article'][0]['attachment'].count).to eq 2
      end

      it 'verify if pdf exists' do
        expect(search_index_attribute_lookup['article'][0]['attachment'][0]['_name']).to eq 'some_file.pdf'
      end

      it 'verify if txt exists' do
        expect(search_index_attribute_lookup['article'][0]['attachment'][1]['_name']).to eq 'some_file.txt'
      end
    end

    context 'when es_attachment_max_size_in_mb takes only one attachment' do
      before { Setting.set('es_attachment_max_size_in_mb', 4) }

      it 'verify count of articles' do
        expect(search_index_attribute_lookup['article'].count).to eq 3
      end

      it 'verify count of attachments' do
        expect(search_index_attribute_lookup['article'][0]['attachment'].count).to eq 1
      end

      it 'verify if pdf exists' do
        expect(search_index_attribute_lookup['article'][0]['attachment'][0]['_name']).to eq 'some_file.pdf'
      end
    end

    context 'when es_attachment_max_size_in_mb takes no attachment' do
      before { Setting.set('es_attachment_max_size_in_mb', 2) }

      it 'verify count of articles' do
        expect(search_index_attribute_lookup['article'].count).to eq 3
      end

      it 'verify count of attachments' do
        expect(search_index_attribute_lookup['article'][0]['attachment'].count).to eq 0
      end
    end

    context 'when es_total_max_size_in_mb takes no attachment and no oversized article' do
      before { Setting.set('es_total_max_size_in_mb', 1) }

      it 'verify count of articles' do
        expect(search_index_attribute_lookup['article'].count).to eq 2
      end

      it 'verify count of attachments' do
        expect(search_index_attribute_lookup['article'][0]['attachment'].count).to eq 0
      end
    end
  end

  describe '#reopen_after_certain_time?' do
    context 'when groups.follow_up_possible is set to "new_ticket_after_certain_time"' do
      let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: 2) }

      context 'when ticket is open' do
        let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'open')) }

        it 'returns false' do
          expect(ticket.reopen_after_certain_time?).to be false
        end
      end

      context 'when ticket is closed' do
        let(:ticket) { create(:ticket, group: group, state: Ticket::State.find_by(name: 'closed')) }

        context 'when it is within configured time frame' do
          it 'returns true' do
            expect(ticket.reopen_after_certain_time?).to be true
          end
        end

        context 'when it is outside configured time frame' do
          before do
            ticket
            travel 3.days
          end

          it 'returns false' do
            expect(ticket.reopen_after_certain_time?).to be false
          end
        end
      end

      context 'when reopen_time_in_days is not set' do
        let(:group) { create(:group, follow_up_possible: 'new_ticket_after_certain_time', reopen_time_in_days: -1) }

        it 'returns false' do
          expect(ticket.reopen_after_certain_time?).to be false
        end
      end
    end
  end
end
