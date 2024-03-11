# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/can_perform_changes_examples'

RSpec.describe 'Ticket::PerformChanges', :aggregate_failures do
  subject(:object) { create(:ticket, group: group, owner: create(:agent, groups: [group])) }

  let(:group) { create(:group) }

  let(:performable) do
    create(:trigger, perform: perform, activator: 'action', execution_condition_mode: 'always', condition: { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => Ticket::State.pluck(:id) } })
  end

  include_examples 'CanPerformChanges', object_name: 'Ticket'

  context 'when invalid data is given' do
    context 'with not existing attribute' do
      let(:perform) do
        {
          'ticket.foobar' => {
            'value' => 'dummy',
          }
        }
      end

      it 'raises an error' do
        expect { object.perform_changes(performable, 'trigger', object, User.first) }
          .to raise_error(RuntimeError, 'The given trigger contains invalid attributes, stopping!')
      end
    end

    context 'with invalid action in "perform" hash' do
      let(:perform) do
        {
          'dummy' => {
            'value' => 'delete',
          }
        }
      end

      it 'raises an error' do
        expect { object.perform_changes(performable, 'trigger', object, User.first) }
          .to raise_error(RuntimeError, 'The given trigger contains no valid actions, stopping!')
      end
    end
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
      expect { object.perform_changes(performable, 'trigger', {}, 1) }
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
      expect { object.perform_changes(performable, 'trigger', object, User.first) }
        .to change { object.reload.state.name }.to('closed')
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
        expect { object.perform_changes(performable, 'trigger', object, User.first) }
          .to change(object, :pending_time).to(be_within(1.minute).of(timestamp))
      end
    end
  end

  # Test for PR https://github.com/zammad/zammad/pull/2862
  context 'with "pending_time" => { "operator": "relative" } in "perform" hash' do
    shared_examples 'verify' do
      it 'verify relative pending time rule' do
        freeze_time do
          interval = relative_value.send(relative_range).from_now

          expect { object.perform_changes(performable, 'trigger', object, User.first) }
            .to change(object, :pending_time).to(be_within(1.minute).of(interval))
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

    context 'when value in days' do
      let(:relative_value) { 2 }
      let(:relative_range) { :days }

      include_examples 'verify'
    end

    context 'when value in minutes' do
      let(:relative_value) { 60 }
      let(:relative_range) { :minutes }

      include_examples 'verify'
    end

    context 'when value in weeks' do
      let(:relative_value) { 2 }
      let(:relative_range) { :weeks }

      include_examples 'verify'
    end
  end

  context 'with tags in "perform" hash' do
    let(:user) { create(:agent, groups: [group]) }

    let(:perform) do
      {
        'ticket.tags' => { 'operator' => tag_operator, 'value' => 'tag1, tag2' }
      }
    end

    context 'with add' do
      let(:tag_operator) { 'add' }

      it 'adds the tags' do
        expect { object.perform_changes(performable, 'trigger', object, user.id) }
          .to change { object.reload.tag_list }.to(%w[tag1 tag2])
      end
    end

    context 'with remove' do
      let(:tag_operator) { 'remove' }

      before do
        %w[tag1 tag2].each { |tag| object.tag_add(tag, 1) }
      end

      it 'removes the tags' do
        expect { object.perform_changes(performable, 'trigger', object, user.id) }
          .to change { object.reload.tag_list }.to([])
      end
    end
  end

  context 'with "pre_condition" in "perform" hash' do
    let(:user) { create(:agent, groups: [group]) }

    let(:perform) do
      {
        'ticket.owner_id' => {
          'pre_condition'    => pre_condition,
          'value'            => value,
          'value_completion' => '',
        }
      }
    end

    context 'with current_user.id' do
      let(:pre_condition) { 'current_user.id' }
      let(:value)         { '' }

      it 'changes to specified value' do
        expect { object.perform_changes(performable, 'trigger', object, user.id) }
          .to change { object.reload.owner.id }.to(user.id)
      end
    end

    context 'with specific user' do
      let(:another_user)  { create(:agent, groups: [group]) }
      let(:pre_condition) { 'specific' }
      let(:value)         { another_user.id }

      it 'changes to specified value' do
        expect { object.perform_changes(performable, 'trigger', object, user.id) }
          .to change { object.reload.owner.id }.to(another_user.id)
      end
    end

    context 'with current_user.id, but missing user' do
      let(:pre_condition) { 'current_user.id' }
      let(:value)         { '' }

      it 'raises an error' do
        expect { object.perform_changes(performable, 'trigger', object, nil) }
          .to raise_error(RuntimeError, "The required parameter 'user_id' is missing.")
      end
    end

    context 'with not_set' do
      let(:pre_condition) { 'not_set' }
      let(:value)         { '' }

      it 'changes to user with id 1' do
        expect { object.perform_changes(performable, 'trigger', object, user.id) }
          .to change { object.reload.owner.id }.to(1)
      end
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
      expect { object.perform_changes(performable, 'trigger', object, User.first) }
        .to change(object, :destroyed?).to(true)
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
      let!(:article) { create(:ticket_article, ticket: object) }
      let!(:new_article) { create(:ticket_article, ticket: object) }

      let(:trigger) do
        build(:trigger,
              perform: {
                'notification.email' => {
                  body:      'Sample notification',
                  recipient: 'ticket_customer',
                  subject:   'Sample subject'
                }
              })
      end

      let(:objects) do
        last_article = nil
        last_internal_article = nil
        last_external_article = nil
        all_articles = object.articles

        if article.nil?
          last_article = all_articles.last
          last_internal_article = all_articles.reverse.find(&:internal?)
          last_external_article = all_articles.reverse.find { |a| !a.internal? }
        else
          last_article = article
          last_internal_article = article.internal? ? article : all_articles.reverse.find(&:internal?)
          last_external_article = article.internal? ? all_articles.reverse.find { |a| !a.internal? } : article
        end

        {
          ticket:                   object,
          article:                  last_article,
          last_article:             last_article,
          last_internal_article:    last_internal_article,
          last_external_article:    last_external_article,
          created_article:          article,
          created_internal_article: article&.internal? ? article : nil,
          created_external_article: article&.internal? ? nil : article,
        }
      end

      # required by Ticket#perform_changes for email notifications
      before do
        allow(NotificationFactory::Mailer).to receive(:template).and_call_original

        article.ticket.group.update(email_address: create(:email_address))
      end

      it 'passes the first article to NotificationFactory::Mailer' do
        object.perform_changes(trigger, 'trigger', { article_id: article.id }, 1)

        expect(NotificationFactory::Mailer)
          .to have_received(:template)
          .with(hash_including(objects: objects))
          .at_least(:once)

        expect(NotificationFactory::Mailer)
          .not_to have_received(:template)
          .with(hash_including(objects: { ticket: object, article: new_article }))
      end
    end
  end

  context 'with a notification trigger' do
    # https://github.com/zammad/zammad/issues/2782
    #
    # Notification triggers should log notification as private or public
    # according to given configuration
    let(:user) { create(:admin, mobile: '+37061010000') }
    let(:perform) do
      {
        notification_key => {
          body:      'Old programmers never die. They just branch to a new address.',
          recipient: 'ticket_agents',
          subject:   'Old programmers never die. They just branch to a new address.'
        }
      }.deep_merge(additional_options).deep_stringify_keys
    end
    let(:notification_key)  { "notification.#{notification_type}" }
    let!(:ticket_article)   { create(:ticket_article, ticket: object) }
    let(:item) do
      {
        object:     'Ticket',
        object_id:  object.id,
        user_id:    user.id,
        type:       'update',
        article_id: ticket_article.id
      }
    end

    before { object.group.users << user }

    shared_examples 'verify log visibility status' do
      shared_examples 'notification trigger' do
        it 'adds Ticket::Article' do
          expect { object.perform_changes(performable, 'trigger', object, user) }
            .to change { object.articles.count }.by(1)
        end

        it 'new Ticket::Article visibility reflects setting' do
          object.perform_changes(performable, 'trigger', object, User.first)
          new_article = object.articles.reload.last
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

    context 'when dispatching email' do
      let(:notification_type) { :email }

      include_examples 'verify log visibility status'
    end

    shared_examples 'add a new article' do
      it 'adds a new article' do
        expect { object.perform_changes(performable, 'trigger', item, user) }
          .to change { object.articles.count }.by(1)
      end
    end

    shared_examples 'add attachment to new article' do
      include_examples 'add a new article'

      it 'adds attachment to the new article' do
        object.perform_changes(performable, 'trigger', item, user)
        article = object.articles.reload.last

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
        object.perform_changes(performable, 'trigger', item, user)
        article = object.articles.reload.last

        expect(article.type.name).to eq('email')
        expect(article.sender.name).to eq('System')
        expect(article.attachments.count).to eq(0)
      end
    end

    context 'when dispatching email with include attachment present' do
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

    context 'when dispatching email with include attachment not present' do
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

    context 'when dispatching SMS' do
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

    let(:context_data) do
      {
        type:      'info',
        execution: 'trigger',
        changes:   { 'state_id' => %w[2 4] },
        user_id:   1,
      }
    end

    it 'schedules the webhooks notification job' do
      expect { object.perform_changes(trigger, 'trigger', context_data, 1) }.to have_enqueued_job(TriggerWebhookJob).with(
        trigger,
        object,
        nil,
        changes:        { 'State' => %w[open closed] },
        user_id:        1,
        execution_type: 'trigger',
        event_type:     'info',
      )
    end
  end

  context 'with a "article.note" trigger' do
    let(:user) { create(:agent, groups: [group]) }

    let(:perform) do
      { 'article.note' => { 'subject' => 'Test subject note', 'internal' => 'true', 'body' => 'Test body note' } }
    end

    it 'adds the note' do
      object.perform_changes(performable, 'trigger', object, user.id)

      expect(object.articles.reload.last).to have_attributes(
        subject:  'Test subject note',
        body:     'Test body note',
        internal: true,
      )
    end
  end

  describe 'Check if blocking notifications works' do
    context 'when mail delivery failed' do
      let(:ticket)   { create(:ticket) }
      let(:customer) { create(:customer) }

      let(:perform) do
        {
          'notification.email' => {
            body:      "Hello \#{ticket.customer.firstname} \#{ticket.customer.lastname},",
            recipient: ["userid_#{customer.id}"],
            subject:   "Autoclose (\#{ticket.title})",
          }
        }
      end

      context 'with a normal user' do
        it 'sends trigger base notification' do
          expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }.to change { ticket.reload.articles.count }.by(1)
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

        it 'sends no trigger base notification' do
          expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }.not_to change { ticket.reload.articles.count }

          expect(customer.reload.preferences).to include(
            mail_delivery_failed:      true,
            mail_delivery_failed_data: failed_date,
          )
        end

        context 'with failed date 61 days ago' do
          let(:failed_date) { 61.days.ago }

          it 'sends trigger base notification' do
            expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }.to change { ticket.reload.articles.count }.by(1)

            expect(customer.reload.preferences).to include(
              mail_delivery_failed:      false,
              mail_delivery_failed_data: nil,
            )
          end
        end

        context 'with failed date 70 days ago' do
          let(:failed_date) { 70.days.ago }

          it 'sends trigger base notification' do
            expect { ticket.perform_changes(performable, 'trigger', ticket, User.first) }.to change { ticket.reload.articles.count }.by(1)

            expect(customer.reload.preferences).to include(
              mail_delivery_failed:      false,
              mail_delivery_failed_data: nil,
            )
          end
        end
      end
    end
  end
end
