require 'rails_helper'

RSpec.describe Ticket do

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

      expect {
        result = target_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      }.to raise_error('ticket already merged, no merge into merged ticket possible')
    end

    it 'prevents merging ticket in it self' do
      source_ticket = create(:ticket)

      expect {
        result = source_ticket.merge_to(
          ticket_id: source_ticket.id,
          user_id:   1,
        )
      }.to raise_error('Can\'t merge ticket with it self!')
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

    it 'performes a ticket state change on a ticket' do
      source_ticket = create(:ticket)

      changes = {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s },
      }

      source_ticket.perform_changes(changes, 'trigger', source_ticket, User.find(1))
      source_ticket.reload

      expect(source_ticket.state.name).to eq('closed')
    end

    it 'performes a ticket deletion on a ticket' do
      source_ticket = create(:ticket)

      changes = {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'closed').id.to_s },
        'ticket.action' => { 'value' => 'delete' },
      }

      source_ticket.perform_changes(changes, 'trigger', source_ticket, User.find(1))
      ticket_with_source_ids = Ticket.where(id: source_ticket.id)
      expect(ticket_with_source_ids).to match_array([])
    end

  end

  context 'callbacks' do

    describe '#reset_pending_time' do

      it 'resets the pending time on state change' do
        ticket = create(:ticket,
                        state:        Ticket::State.lookup(name: 'pending reminder'),
                        pending_time: Time.zone.now + 2.days)
        expect(ticket.pending_time).not_to be nil

        ticket.update_attribute(:state, Ticket::State.lookup(name: 'open'))
        expect(ticket.pending_time).to be nil
      end

      it 'lets handle ActiveRecord nil as new value' do
        ticket = create(:ticket)
        expect do
          ticket.update_attribute(:state, nil)
        end.to raise_error(ActiveRecord::StatementInvalid)
      end

    end
  end
end
