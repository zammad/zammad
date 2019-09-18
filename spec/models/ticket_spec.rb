require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/can_lookup_examples'
require 'models/concerns/has_history_examples'
require 'models/concerns/has_tags_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'

RSpec.describe Ticket, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'CanLookup'
  it_behaves_like 'HasHistory', history_relation_object: 'Ticket::Article'
  it_behaves_like 'HasTags'
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ticket
  it_behaves_like 'HasObjectManagerAttributesValidation'

  subject(:ticket) { create(:ticket) }

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
    end
  end

  describe 'Instance methods:' do
    describe '#merge_to' do
      let(:target_ticket) { create(:ticket) }

      context 'when source ticket has Links' do
        let(:linked_tickets) { create_list(:ticket, 3) }
        let(:links) { linked_tickets.map { |l| create(:link, from: ticket, to: l) } }

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
            .to raise_error("Can't merge ticket with it self!")
        end
      end

      # Issue #2469 - Add information "Ticket merged" to History
      context 'when merging' do
        let(:merge_user) { create(:user) }

        before do
          # create target ticket early
          # to avoid a race condition
          # when creating the history entries
          target_ticket
          travel 5.minutes
        end

        it 'creates history entries in both the origin ticket and the target ticket' do
          ticket.merge_to(ticket_id: target_ticket.id, user_id: merge_user.id)

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
      end
    end

    describe '#perform_changes' do
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
          expect { ticket.perform_changes(perform, 'trigger', {}, 1) }
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
          expect { ticket.perform_changes(perform, 'trigger', ticket, User.first) }
            .to change { ticket.reload.state.name }.to('closed')
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
          expect { ticket.perform_changes(perform, 'trigger', ticket, User.first) }
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

            ticket.perform_changes(trigger.perform, 'trigger', { article_id: article.id }, 1)
          end
        end
      end
    end

    describe '#access?' do
      context 'when given ticket’s owner' do
        it 'returns true for both "read" and "full" privileges' do
          expect(ticket.access?(ticket.owner, 'read')).to be(true)
          expect(ticket.access?(ticket.owner, 'full')).to be(true)
        end
      end

      context 'when given the ticket’s customer' do
        it 'returns true for both "read" and "full" privileges' do
          expect(ticket.access?(ticket.customer, 'read')).to be(true)
          expect(ticket.access?(ticket.customer, 'full')).to be(true)
        end
      end

      context 'when given a user that is neither owner nor customer' do
        let(:user) { create(:agent_user) }

        it 'returns false for both "read" and "full" privileges' do
          expect(ticket.access?(user, 'read')).to be(false)
          expect(ticket.access?(user, 'full')).to be(false)
        end

        context 'but the user is an agent with full access to ticket’s group' do
          before { user.group_names_access_map = { ticket.group.name => 'full' } }

          it 'returns true for both "read" and "full" privileges' do
            expect(ticket.access?(user, 'read')).to be(true)
            expect(ticket.access?(user, 'full')).to be(true)
          end
        end

        context 'but the user is a customer from the same organization as ticket’s customer' do
          subject(:ticket) { create(:ticket, customer: customer) }

          let(:customer) { create(:customer_user, organization: create(:organization)) }
          let(:colleague) { create(:customer_user, organization: customer.organization) }

          context 'and organization.shared is true (default)' do
            it 'returns true for both "read" and "full" privileges' do
              expect(ticket.access?(colleague, 'read')).to be(true)
              expect(ticket.access?(colleague, 'full')).to be(true)
            end
          end

          context 'but organization.shared is false' do
            before { customer.organization.update(shared: false) }

            it 'returns false for both "read" and "full" privileges' do
              expect(ticket.access?(colleague, 'read')).to be(false)
              expect(ticket.access?(colleague, 'full')).to be(false)
            end
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
  end

  describe 'Attributes:' do
    describe '#owner' do
      let(:original_owner) { create(:agent_user, groups: [ticket.group]) }

      before { ticket.update(owner: original_owner) }

      context 'when assigned directly' do
        context 'to an active agent belonging to ticket.group' do
          let(:agent) { create(:agent_user, groups: [ticket.group]) }

          it 'can be set' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(agent)
          end
        end

        context 'to an agent not belonging to ticket.group' do
          let(:agent) { create(:agent_user, groups: [other_group]) }
          let(:other_group) { create(:group) }

          it 'resets to default user (id: 1) instead' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'to an inactive agent' do
          let(:agent) { create(:agent_user, groups: [ticket.group], active: false) }

          it 'resets to default user (id: 1) instead' do
            expect { ticket.update(owner: agent) }
              .to change { ticket.reload.owner }.to(User.first)
          end
        end

        context 'to a non-agent' do
          let(:agent) { create(:customer_user, groups: [ticket.group]) }

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
            expect { create(:ticket_article, ticket: ticket) }
              .to change { ticket.reload.owner }.to(User.first)
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
      subject(:ticket) { create(:ticket, pending_time: Time.zone.now + 2.days) }

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
      before { travel_to(Time.current) }  # freeze time

      let(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.escalation_at).to be(nil)
        end
      end

      context 'with an SLA in the system' do
        before { sla }  # create sla

        it 'is set based on SLA’s #first_response_time' do
          expect(ticket.reload.escalation_at.to_i)
            .to eq(1.hour.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket }  # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'is updated based on the SLA’s #update_time' do
            travel(1.minute)  # time is frozen: if we don't travel forward, pre- and post-update values will be the same

            expect { article }
              .to change { ticket.reload.escalation_at.to_i }
              .to eq(3.hours.from_now.to_i)
          end

          context 'when new #update_time is later than original #solution_time' do
            it 'is updated based on the original #solution_time' do
              travel(2.hours)  # time is frozen: if we don't travel forward, pre- and post-update values will be the same

              expect { article }
                .to change { ticket.reload.escalation_at.to_i }
                .to eq(4.hours.after(ticket.created_at).to_i)
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
    end

    describe '#first_response_escalation_at' do
      before { travel_to(Time.current) }  # freeze time

      let(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.first_response_escalation_at).to be(nil)
        end
      end

      context 'with an SLA in the system' do
        before { sla }  # create sla

        it 'is set based on SLA’s #first_response_time' do
          expect(ticket.reload.first_response_escalation_at.to_i)
            .to eq(1.hour.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket }  # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'does not change' do
            expect { article }.not_to change(ticket, :first_response_escalation_at)
          end
        end
      end
    end

    describe '#update_escalation_at' do
      before { travel_to(Time.current) }  # freeze time

      let(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.update_escalation_at).to be(nil)
        end
      end

      context 'with an SLA in the system' do
        before { sla }  # create sla

        it 'is set based on SLA’s #update_time' do
          expect(ticket.reload.update_escalation_at.to_i)
            .to eq(3.hours.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket }  # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'is updated based on the SLA’s #update_time' do
            travel(1.minute)  # time is frozen: if we don't travel forward, pre- and post-update values will be the same

            expect { article }
              .to change { ticket.reload.update_escalation_at.to_i }
              .to(3.hours.from_now.to_i)
          end
        end
      end
    end

    describe '#close_escalation_at' do
      before { travel_to(Time.current) }  # freeze time

      let(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 180, solution_time: 240) }
      let(:calendar) { create(:calendar, :'24/7') }

      context 'with no SLAs in the system' do
        it 'defaults to nil' do
          expect(ticket.close_escalation_at).to be(nil)
        end
      end

      context 'with an SLA in the system' do
        before { sla }  # create sla

        it 'is set based on SLA’s #solution_time' do
          expect(ticket.reload.close_escalation_at.to_i)
            .to eq(4.hours.from_now.to_i)
        end

        context 'after first agent’s response' do
          before { ticket }  # create ticket

          let(:article) { create(:ticket_article, ticket: ticket, sender_name: 'Agent') }

          it 'does not change' do
            expect { article }.not_to change(ticket, :close_escalation_at)
          end
        end
      end
    end
  end

  describe 'Associations:' do
    describe '#organization' do
      subject(:ticket) { build(:ticket, customer: customer, organization: nil) }

      let(:customer) { create(:customer, :with_org) }

      context 'on creation' do
        it 'automatically adopts the organization of its #customer' do
          expect { ticket.save }
            .to change(ticket, :organization).to(customer.organization)
        end
      end

      context 'on update of #customer.organization' do
        context 'to nil' do
          it 'automatically updates to #customer’s new value' do
            ticket.save

            expect { customer.update(organization: nil) }
              .to change { ticket.reload.organization }.to(nil)
          end
        end

        context 'to a different organization' do
          let(:new_org) { create(:organization) }

          it 'automatically updates to #customer’s new value' do
            ticket.save

            expect { customer.update(organization: new_org) }
              .to change { ticket.reload.organization }.to(new_org)
          end
        end
      end
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

    describe 'Cti::CallerId syncing:' do
      subject(:ticket) { build(:ticket) }

      before { allow(Cti::CallerId).to receive(:build) }

      it 'adds numbers in article bodies (via Cti::CallerId.build)' do
        expect(Cti::CallerId).to receive(:build).with(ticket)

        ticket.save
        Observer::Transaction.commit
        Scheduler.worker(true)
      end
    end

    describe 'Touching associations on update:' do
      subject(:ticket) { create(:ticket, customer: customer) }

      let(:customer) { create(:customer_user, organization: organization) }
      let(:organization) { create(:organization) }
      let(:other_customer) { create(:customer_user, organization: other_organization) }
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

      context 'when organization has 100+ members' do
        let!(:other_members) { create_list(:user, 100, organization: organization) }

        context 'and customer association is changed' do
          it 'touches both old and new customer, and their organizations' do
            expect { ticket.update(customer: other_customer) }
              .to change { customer.reload.updated_at }
              .and change { organization.reload.updated_at }
              .and change { other_customer.reload.updated_at }
              .and change { other_organization.reload.updated_at }
          end
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

      it 'deletes all related Karma::ActivityLogs on destroy' do
        create_list(:'karma/activity_log', 3, o: ticket)

        expect { ticket.destroy }
          .to change { Karma::ActivityLog.exists?(object_lookup_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id) }
          .to(false)
      end

      it 'deletes all related RecentViews on destroy' do
        create_list(:recent_view, 3, o: ticket)

        expect { ticket.destroy }
          .to change { RecentView.exists?(recent_view_object_id: ObjectLookup.by_name('Ticket'), o_id: ticket.id) }
          .to(false)
      end

      context 'when ticket is generated from email (with attachments)' do
        subject(:ticket) { Channel::EmailParser.new.process({}, raw_email).first }

        let(:raw_email) { File.read(Rails.root.join('test', 'data', 'mail', 'mail001.box')) }

        it 'adds attachments to the Store{::File,::Provider::DB} tables' do
          expect { ticket }
            .to change(Store, :count).by(2)
            .and change { Store::File.count }.by(2)
            .and change { Store::Provider::DB.count }.by(2)
        end

        context 'and subsequently destroyed' do
          it 'deletes all related attachments' do
            ticket  # create ticket

            expect { ticket.destroy }
              .to change(Store, :count).by(-2)
              .and change { Store::File.count }.by(-2)
              .and change { Store::Provider::DB.count }.by(-2)
          end
        end

        context 'and a duplicate ticket is generated from the same email' do
          before { ticket }  # create ticket

          let(:duplicate) { Channel::EmailParser.new.process({}, raw_email).first }

          it 'adds duplicate attachments to the Store table only' do
            expect { duplicate }
              .to change(Store, :count).by(2)
              .and change { Store::File.count }.by(0)
              .and change { Store::Provider::DB.count }.by(0)
          end

          context 'when only the duplicate ticket is destroyed' do
            it 'deletes only the duplicate attachments' do
              duplicate  # create ticket

              expect { duplicate.destroy }
                .to change(Store, :count).by(-2)
                .and change { Store::File.count }.by(0)
                .and change { Store::Provider::DB.count }.by(0)
            end
          end

          context 'when only the duplicate ticket is destroyed' do
            it 'deletes all related attachments' do
              duplicate.destroy

              expect { ticket.destroy }
                .to change(Store, :count).by(-2)
                .and change { Store::File.count }.by(-2)
                .and change { Store::Provider::DB.count }.by(-2)
            end
          end
        end
      end
    end
  end
end
