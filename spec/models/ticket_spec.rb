require 'rails_helper'
require 'models/concerns/can_lookup_examples'

RSpec.describe Ticket do
  include_examples 'CanLookup'

  describe '#merge_to' do

    it 'reassigns all links to the target ticket after merge' do
      source_ticket     = create(:ticket)
      target_ticket     = create(:ticket)

      important_ticket1 = create(:ticket)
      important_ticket2 = create(:ticket)
      important_ticket3 = create(:ticket)

      create(:link, link_object_source_value: source_ticket.id, link_object_target_value: important_ticket1.id)
      create(:link, link_object_source_value: source_ticket.id, link_object_target_value: important_ticket2.id)
      create(:link, link_object_source_value: source_ticket.id, link_object_target_value: important_ticket3.id)

      source_ticket.merge_to(
        ticket_id: target_ticket.id,
        user_id:   1,
      )

      links = Link.list(
        link_object: 'Ticket',
        link_object_value: target_ticket.id,
      )

      expected_ticket_ids = [source_ticket.id, important_ticket1.id, important_ticket2.id, important_ticket3.id ]
      check_ticket_ids    = links.collect { |link| link['link_object_value'] }

      expect(check_ticket_ids).to match_array(expected_ticket_ids)
    end

    it 'prevents cross merging tickets' do
      source_ticket     = create(:ticket)
      target_ticket     = create(:ticket)

      result = source_ticket.merge_to(
        ticket_id: target_ticket.id,
        user_id:   1,
      )
      expect(result).to be(true)

      expect do
        result = target_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      end.to raise_error('ticket already merged, no merge into merged ticket possible')
    end

    it 'prevents merging ticket in it self' do
      source_ticket = create(:ticket)

      expect do
        result = source_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      end.to raise_error('Can\'t merge ticket with it self!')
    end

  end

  describe '#destroy' do

    it 'deletes all related objects before destroy' do
      ApplicationHandleInfo.current = 'application_server'

      source_ticket = create(:ticket)

      # create some links
      important_ticket1 = create(:ticket)
      important_ticket2 = create(:ticket)
      important_ticket3 = create(:ticket)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id)
      create(:ticket_article, ticket_id: source_ticket.id)
      create(:ticket_article, ticket_id: source_ticket.id)

      create(:link, link_object_source_value: source_ticket.id, link_object_target_value: important_ticket1.id)
      create(:link, link_object_source_value: important_ticket2.id, link_object_target_value: source_ticket.id)
      create(:link, link_object_source_value: source_ticket.id, link_object_target_value: important_ticket3.id)

      create(:online_notification, o_id: source_ticket.id)
      create(:tag, o_id: source_ticket.id)

      Observer::Transaction.commit
      Scheduler.worker(true)

      # get before destroy
      activities = ActivityStream.where(
        activity_stream_object_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      links = Link.list(
        link_object: 'Ticket',
        link_object_value: source_ticket.id
      )
      articles = Ticket::Article.where(ticket_id: source_ticket.id)
      history = History.list('Ticket', source_ticket.id, nil, true)
      karma_log = Karma::ActivityLog.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      online_notifications = OnlineNotification.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      recent_views = OnlineNotification.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      tags = Tag.tag_list(
        object: 'Ticket',
        o_id: source_ticket.id,
      )

      # check before destroy
      expect(activities.count).to be >= 0
      expect(links.count).to be >= 0
      expect(articles.count).to be >= 0
      expect(history[:list].count).to be >= 0
      expect(karma_log.count).to be >= 0
      expect(online_notifications.count).to be >= 0
      expect(recent_views.count).to be >= 0
      expect(tags.count).to be >= 0

      # destroy ticket
      source_ticket.destroy

      # get after destroy
      activities = ActivityStream.where(
        activity_stream_object_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      links = Link.list(
        link_object: 'Ticket',
        link_object_value: source_ticket.id
      )
      articles = Ticket::Article.where(ticket_id: source_ticket.id)
      history = History.list('Ticket', source_ticket.id, nil, true)
      karma_log = Karma::ActivityLog.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      online_notifications = OnlineNotification.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      recent_views = OnlineNotification.where(
        object_lookup_id: ObjectLookup.by_name('Ticket'),
        o_id: source_ticket.id,
      )
      tags = Tag.tag_list(
        object: 'Ticket',
        o_id: source_ticket.id,
      )

      # check after destroy
      expect(activities.count).to be == 0
      expect(links.count).to be == 0
      expect(articles.count).to be == 0
      expect(history[:list].count).to be == 0
      expect(karma_log.count).to be == 0
      expect(online_notifications.count).to be == 0
      expect(recent_views.count).to be == 0
      expect(tags.count).to be == 0

    end

  end

  describe '#perform_changes' do

    it 'performs a ticket state change on a ticket' do
      source_ticket = create(:ticket)

      changes = {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s },
      }

      source_ticket.perform_changes(changes, 'trigger', source_ticket, User.find(1))
      source_ticket.reload

      expect(source_ticket.state.name).to eq('closed')
    end

    it 'performs a ticket deletion on a ticket' do
      source_ticket = create(:ticket)

      changes = {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s },
        'ticket.action' => { 'value' => 'delete' },
      }

      source_ticket.perform_changes(changes, 'trigger', source_ticket, User.find(1))
      ticket_with_source_ids = Ticket.where(id: source_ticket.id)
      expect(ticket_with_source_ids).to match_array([])
    end

    # Regression test for https://github.com/zammad/zammad/issues/2001
    it 'does not modify its arguments' do
      trigger = Trigger.new(
        perform: {
          'notification.email' => {
            body: "Hello \#{ticket.customer.firstname} \#{ticket.customer.lastname},",
            recipient: %w[article_last_sender ticket_owner ticket_customer ticket_agents],
            subject: "Autoclose (\#{ticket.title})"
          }
        }
      )

      expect { Ticket.first.perform_changes(trigger.perform, 'trigger', {}, 1) }
        .to not_change { trigger.perform['notification.email'][:body] }
        .and not_change { trigger.perform['notification.email'][:subject] }
    end

    # Regression test for https://github.com/zammad/zammad/issues/1543
    #
    # If a new article fires an email notification trigger,
    # and then another article is added to the same ticket
    # before that trigger is performed,
    # the email template's 'article' var should refer to the originating article,
    # not the newest one.
    #
    # (This occurs whenever one action fires multiple email notification triggers.)
    it 'passes the correct article to NotificationFactory::Mailer' do
      # required by Ticket#perform_changes for email notifications
      Group.first.update(email_address: create(:email_address))

      ticket        = Ticket.first
      orig_article  = Ticket::Article.where(ticket_id: ticket.id).first
      newer_article = create(:ticket_article, ticket_id: ticket.id)
      trigger       = Trigger.new(
        perform: {
          'notification.email' => {
            body: '',
            recipient: 'ticket_customer',
            subject: ''
          }
        }
      )

      allow(NotificationFactory::Mailer).to receive(:template).and_return('')

      ticket.perform_changes(trigger.perform, 'trigger', { article_id: orig_article.id }, 1)

      expect(NotificationFactory::Mailer)
        .to have_received(:template)
        .with(hash_including(objects: { ticket: ticket, article: orig_article }))
        .at_least(:once)

      expect(NotificationFactory::Mailer)
        .not_to have_received(:template)
        .with(hash_including(objects: { ticket: ticket, article: newer_article }))
    end
  end

  describe '#selectors' do

    # https://github.com/zammad/zammad/issues/1769
    it 'does not return multiple results for a single ticket' do
      source_ticket = create(:ticket)
      source_ticket2 = create(:ticket)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@blubselector.de')
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf2@blubselector.de')
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf3@blubselector.de')
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf4@blubselector.de')
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf5@blubselector.de')
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf6@blubselector.de')

      condition = {
        'article.from' => {
          operator: 'contains',
          value: 'blubselector.de',
        },
      }

      ticket_count, tickets = Ticket.selectors(condition, 100, nil, 'full')

      expect(ticket_count).to be == 2
      expect(tickets.count).to be == 2
    end
  end

  context 'callbacks' do

    describe '#reset_pending_time' do

      it 'resets the pending time on state change' do
        ticket = create(:ticket,
                        state:        Ticket::State.lookup(name: 'pending reminder'),
                        pending_time: Time.zone.now + 2.days)
        expect(ticket.pending_time).not_to be nil

        ticket.update!(state: Ticket::State.lookup(name: 'open'))
        expect(ticket.pending_time).to be nil
      end

      it 'lets handle ActiveRecord nil as new value' do
        ticket = create(:ticket)
        expect do
          ticket.update!(state: nil)
        end.to raise_error(ActiveRecord::StatementInvalid)
      end

    end
  end

  describe '#access?' do

    context 'agent' do

      it 'allows owner access' do

        owner  = create(:agent_user)
        ticket = create(:ticket, owner: owner)

        expect( ticket.access?(owner, 'full') ).to be(true)
      end

      it 'allows group access' do

        agent  = create(:agent_user)
        group  = create(:group)
        ticket = create(:ticket, group: group)

        agent.group_names_access_map = {
          group.name => 'full',
        }

        expect( ticket.access?(agent, 'full') ).to be(true)
      end

      it 'prevents unauthorized access' do
        agent  = create(:agent_user)
        ticket = create(:ticket)

        expect( ticket.access?(agent, 'read') ).to be(false)
      end
    end

    context 'customer' do

      it 'allows assigned access' do

        customer = create(:customer_user)
        ticket   = create(:ticket, customer: customer)

        expect( ticket.access?(customer, 'full') ).to be(true)
      end

      context 'organization' do

        it 'allows access for shared' do

          organization = create(:organization)
          assigned     = create(:customer_user, organization: organization)
          collegue     = create(:customer_user, organization: organization)
          ticket       = create(:ticket, customer: assigned)

          expect( ticket.access?(collegue, 'full') ).to be(true)
        end

        it 'prevents unshared access' do

          organization = create(:organization, shared: false)
          assigned     = create(:customer_user, organization: organization)
          collegue     = create(:customer_user, organization: organization)
          ticket       = create(:ticket, customer: assigned)

          expect( ticket.access?(collegue, 'full') ).to be(false)
        end
      end

      it 'prevents unauthorized access' do
        customer = create(:customer_user)
        ticket   = create(:ticket)

        expect( ticket.access?(customer, 'read') ).to be(false)
      end
    end
  end
end
