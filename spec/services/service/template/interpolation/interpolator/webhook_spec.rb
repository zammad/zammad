# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Template::Interpolation::Interpolator::Webhook do

  # rubocop:disable Lint/InterpolationCheck
  describe '#execute' do
    subject(:execute) { described_class.new(template: template, tracks: tracks, additional_track_generate_data: webhook_data).execute }

    let(:ticket)                   { create(:ticket, time_unit: 123) }
    let(:article)                  { create(:ticket_article, body: "Text with\nnew line.") }
    let(:tracks)                   { { ticket:, article: } }
    let(:webhook_data)             { nil }
    let(:event) do
      {
        type:      'info',
        execution: 'trigger',
        changes:   { 'state' => %w[open closed] },
        user_id:   1,
      }
    end

    context 'when the payload is empty' do
      let(:template) { {}.to_json }
      let(:json_data) { {} }

      it 'returns an empty JSON object' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder is empty' do
      let(:template) { { 'ticket' => '#{}' }.to_json }
      let(:json_data) { { 'ticket' => '#{}' } }

      it 'returns the placeholder' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder is invalid' do
      let(:template) { { 'ticket' => '#{ticket.title', 'article' => '#{article.id article.note}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.title', 'article' => '#{article.id article.note}' } }

      it 'returns the placeholder' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder base object ticket or article is missing' do
      let(:template) { { 'ticket' => '#{.title}' }.to_json }
      let(:json_data) { { 'ticket' => '#{no object provided}' } }

      it 'returns the placeholder reporting "no object provided"' do
        expect(execute).to eq(json_data)
      end

    end

    context 'when the placeholder base object is other than ticket or article' do
      let(:template) { { 'user' => '#{user}' }.to_json }
      let(:json_data) { { 'user' => '#{user / no such object}' } }

      it 'returns the placehodler reporting "no such object"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains only base object ticket or article' do
      let(:template) { { 'ticket' => '#{ticket}', 'Article' => '#{article}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket / missing method}', 'Article' => '#{article / missing method}' } }

      it 'returns the placeholder reporting "missing method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains denied method' do
      let(:template) { { 'ticket' => '#{ticket.articles}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.articles / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains denied attribute' do
      let(:template) { { 'ticket.owner' => '#{ticket.owner.password}' }.to_json }
      let(:json_data) { { 'ticket.owner' => '#{ticket.owner.password / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains danger method' do
      let(:template) { { 'ticket.owner' => '#{ticket.destroy!}' }.to_json }
      let(:json_data) { { 'ticket.owner' => '#{ticket.destroy! / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder ends with complex object' do
      let(:template) { { 'ticket' => '#{ticket.group}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.group / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains valid object and invalid method' do
      let(:template) { { 'ticket' => '#{ticket.1_article}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.1_article / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains valid object and method' do
      let(:template) { { 'ticket.id' => '#{ticket.id}' }.to_json }
      let(:json_data) { { 'ticket.id' => ticket.id } }

      it 'returns the determined value' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains valid object and method, but the value is nil' do
      let(:template) do
        {
          'ticket.organization.name' => '#{ticket.organization.name}',
          'ticket.title'             => '#{ticket.title}'
        }.to_json
      end
      let(:json_data) do
        {
          'ticket.organization.name' => '',
          'ticket.title'             => ticket.title
        }
      end

      it 'returns an empty string' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains multiple valid object and method' do
      let(:template) do
        {
          'ticket'  => { 'owner' => '#{ticket.owner.fullname}' },
          'article' => { 'created_at' => '#{article.created_at}' }
        }.to_json
      end
      let(:json_data) do
        {
          'ticket'  => { 'owner' => ticket.owner.fullname.to_s },
          'article' => { 'created_at' => article.created_at.to_s }
        }
      end

      it 'returns the determined value' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the placeholder contains multiple attributes' do
      let(:template) do
        {
          'my_field'  => 'Test #{ticket.id} // #{ticket.group.name} Test',
          'my_field2' => '#{ticket.id} // #{ticket.group.name} Test',
          'my_field3' => '#{ticket.id}',
          'my_field4' => '#{ticket.group.name}',
        }.to_json
      end
      let(:json_data) do
        {
          'my_field'  => "Test #{ticket.id} // #{ticket.group.name} Test",
          'my_field2' => "#{ticket.id} // #{ticket.group.name} Test",
          'my_field3' => ticket.id,
          'my_field4' => ticket.group.name.to_s,
        }
      end

      it 'returns the placeholder reporting "no such method"' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the payload contains a complex structure' do
      let(:template) do
        {
          'current_user' => '#{current_user.fullname}',
          'fqdn'         => '#{config.fqdn}',
          'ticket'       => {
            'id'        => '#{ticket.id}',
            'owner'     => '#{ticket.owner.fullname}',
            'group'     => '#{ticket.group.name}',
            'time_unit' => '#{ticket.time_unit}',
            'article'   => {
              'id'          => '#{article.id}',
              'created_at'  => '#{article.created_at}',
              'subject'     => '#{article.subject}',
              'body'        => '#{article.body}',
              'attachments' => '#{article.attachments}',
              'internal'    => '#{article.internal}',
            }
          }
        }.to_json
      end
      let(:json_data) do
        {
          'current_user' => '#{current_user / no such object}',
          'fqdn'         => Setting.get('fqdn'),
          'ticket'       => {
            'id'        => ticket.id,
            'owner'     => ticket.owner.fullname.to_s,
            'group'     => ticket.group.name.to_s,
            'time_unit' => ticket.time_unit.to_s,
            'article'   => {
              'id'          => article.id,
              'created_at'  => article.created_at.to_s,
              'subject'     => article.subject.to_s,
              'body'        => article.body.to_s,
              'attachments' => '#{article.attachments / no such method}',
              'internal'    => article.internal
            }
          }
        }
      end

      it 'returns a valid JSON payload' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when the replacement value contains double quotes' do
      let(:ticket)    { create(:ticket, title: 'Test "Title"') }
      let(:template)    { { 'ticket.title' => '#{ticket.title}' }.to_json }
      let(:json_data)   { { 'ticket.title' => 'Test "Title"' } }

      it 'returns the determined value' do
        expect(execute).to eq(json_data)
      end
    end

    context 'when object attributes are used in the placeholder', db_strategy: :reset do
      let(:ticket) { create(:ticket, object_manager_attribute_name => object_manager_attribute_value) }

      before do
        create_object_manager_attribute
        ObjectManager::Attribute.migration_execute
      end

      shared_examples 'check different usage' do
        context 'when used in string context' do
          let(:template) do
            {
              "ticket.#{object_manager_attribute_name}" => "Test \#{ticket.#{object_manager_attribute_name}}"
            }.to_json
          end
          let(:json_data) do
            {
              "ticket.#{object_manager_attribute_name}" => "Test #{object_manager_attribute_value}"
            }
          end

          it 'returns the determined value' do
            expect(execute).to eq(json_data)
          end
        end

        context 'when used in direct context' do
          let(:template) do
            {
              "ticket.#{object_manager_attribute_name}" => "\#{ticket.#{object_manager_attribute_name}}"
            }.to_json
          end
          let(:json_data) do
            {
              "ticket.#{object_manager_attribute_name}" => object_manager_attribute_value
            }
          end

          it 'returns the determined value' do
            expect(execute).to eq(json_data)
          end
        end
      end

      context 'when multiselect is used inside the ticket' do
        let(:object_manager_attribute_name)  { 'multiselect_keys_001' }
        let(:object_manager_attribute_value) { %w[key_1 key_3] }
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_multiselect, name: object_manager_attribute_name)
        end

        include_examples 'check different usage'
      end

      context 'when external data source is used inside the ticket' do
        let(:object_manager_attribute_name)  { 'autocompletion_ajax_external_data_source' }
        let(:object_manager_attribute_value) do
          {
            'value' => 123,
            'label' => 'Example',
          }
        end
        let(:create_object_manager_attribute) do
          create(:object_manager_attribute_autocompletion_ajax_external_data_source, name: object_manager_attribute_name)
        end

        include_examples 'check different usage'
      end
    end

    describe "when the placeholder contains object 'notification'" do
      let(:template) do
        {
          'subject' => '#{notification.subject}',
          'message' => '#{notification.message}',
          'changes' => '#{notification.changes}',
          'body'    => '#{notification.body}',
          'link'    => '#{notification.link}',
        }.to_json
      end
      let(:webhook_data) do
        {
          event:   event,
          webhook: nil
        }
      end

      context "when the event is of the type 'create'" do
        let(:event) do
          {
            type:      'create',
            execution: 'trigger',
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Created by')
          expect(execute['changes']).to include('State: new')
        end
      end

      context "when the event is of the type 'update'" do
        let(:event) do
          {
            type:      'update',
            execution: 'trigger',
            changes:   { 'state' => %w[open closed] },
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Updated by')
          expect(execute['changes']).to include('state: open -> closed')
        end

        context 'without changes' do
          let(:event) do
            {
              type:      'update',
              execution: 'trigger',
              user_id:   1,
            }
          end

          it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
            expect(execute['subject']).to eq(ticket.title)
            expect(execute['body']).to eq(article.body_as_text)
            expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
            expect(execute['message']).to include('Updated by')
          end
        end
      end

      context "when the event is of the type 'info'" do
        let(:event) do
          {
            type:      'info',
            execution: 'trigger',
            changes:   { 'state' => %w[open closed] },
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Last updated at')
        end
      end

      context "when the event is of the type 'escalation'" do
        let(:event) do
          {
            type:      'escalation',
            execution: 'trigger',
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Escalated at')
          expect(execute['changes']).to include('has been escalated since')
        end
      end

      context "when the event is of the type 'escalation warning'" do
        let(:event) do
          {
            type:      'escalation_warning',
            execution: 'trigger',
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Will escalate at')
          expect(execute['changes']).to include('will escalate at')
        end
      end

      context "when the event is of the type 'reminder reached'" do
        let(:event) do
          {
            type:      'reminder_reached',
            execution: 'trigger',
            user_id:   1,
          }
        end

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to eq(article.body_as_text)
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Reminder reached!')
          expect(execute['changes']).to include('reminder reached for')
        end
      end

      context "when the event is triggered by a 'job'" do
        let(:event) do
          {
            type:      '',
            execution: 'job',
            changes:   { 'state' => %w[open closed] },
            user_id:   1,
          }
        end

        let(:article) { nil }
        let(:tracks)  { { ticket:, article: } }

        it 'returns a valid json with a notification factory generated information"', :aggregate_failures do
          expect(execute['subject']).to eq(ticket.title)
          expect(execute['body']).to be_empty
          expect(execute['link']).to match(%r{http.*#ticket/zoom/#{ticket.id}$})
          expect(execute['message']).to include('Last updated at')
        end
      end
    end

    describe 'when the payload is a pre-defined webhook' do
      let(:webhook) { create(:mattermost_webhook) }
      let(:webhook_data) do
        {
          event:   event,
          webhook: webhook
        }
      end
      let(:template) { Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook.payload('Mattermost') }

      it 'returns a valid json with webhook information"', :aggregate_failures do
        info = webhook.preferences[:pre_defined_webhook]

        expect(execute[:channel]).to eq(info[:channel])
        expect(execute[:icon_url]).to eq(info[:icon_url])
      end

      context 'when event has no changes' do
        let(:event) do
          {
            type:      'info',
            execution: 'trigger',
            changes:   { 'state' => %w[open closed] },
            user_id:   1,
          }
        end

        it "returns a valid json with webhook information without 'attachments'", :aggregate_failures do
          info = webhook.preferences[:pre_defined_webhook]

          expect(execute[:channel]).to eq(info[:channel])
          expect(execute[:icon_url]).to eq(info[:icon_url])
          expect(execute).to not_include(:attachments)
        end
      end

      context 'when pre-defined webhook has no additional values' do
        let(:webhook) { create(:slack_webhook) }
        let(:webhook_data) do
          {
            event:   event,
            webhook: webhook
          }
        end
        let(:template) { Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook.payload('Slack') }

        it 'returns a valid json with webhook information"', :aggregate_failures do
          expect(execute['text']).to eq("# #{ticket.title}")
        end
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck

  describe '.replacements' do
    subject(:replacements) { described_class.replacements(pre_defined_webhook_type: 'Mattermost') }

    it 'returns a hash with the replacement variables', :aggregate_failures do
      expect(replacements).to be_a(Hash)
      expect(replacements.keys).to include(:article, :ticket, :notification, :webhook)
    end
  end
end
