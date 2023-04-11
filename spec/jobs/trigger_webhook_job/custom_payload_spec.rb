# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerWebhookJob::CustomPayload do

  # rubocop:disable Lint/InterpolationCheck
  describe '.generate' do
    subject(:generate) { described_class.generate(record, { ticket:, article: }, event) }

    let(:ticket)  { create(:ticket) }
    let(:article) { create(:ticket_article) }
    let(:event)   { {} }

    context 'when the payload is empty' do
      let(:record) { {}.to_json }
      let(:json_data) { {} }

      it 'returns an empty JSON object' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder is empty' do
      let(:record) { { 'ticket' => '#{}' }.to_json }
      let(:json_data) { { 'ticket' => '#{}' } }

      it 'returns the placeholder' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder is invalid' do
      let(:record) { { 'ticket' => '#{ticket.title', 'article' => '#{article.id article.note}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.title', 'article' => '#{article.id article.note}' } }

      it 'returns the placeholder' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder base object ticket or article is missing' do
      let(:record) { { 'ticket' => '#{.title}' }.to_json }
      let(:json_data) { { 'ticket' => '#{no object provided}' } }

      it 'returns the placeholder reporting "no object provided"' do
        expect(generate).to eq(json_data)
      end

    end

    context 'when the placeholder base object is other than ticket or article' do
      let(:record) { { 'user' => '#{user}' }.to_json }
      let(:json_data) { { 'user' => '#{user / no such object}' } }

      it 'returns the placehodler reporting "no such object"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains only base object ticket or article' do
      let(:record) { { 'ticket' => '#{ticket}', 'Article' => '#{article}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket / missing method}', 'Article' => '#{article / missing method}' } }

      it 'returns the placeholder reporting "missing method"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains denied method' do
      let(:record) { { 'ticket' => '#{ticket.articles}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.articles / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains denied attribute' do
      let(:record) { { 'ticket.owner' => '#{ticket.owner.password}' }.to_json }
      let(:json_data) { { 'ticket.owner' => '#{ticket.owner.password / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains danger method' do
      let(:record) { { 'ticket.owner' => '#{ticket.destroy!}' }.to_json }
      let(:json_data) { { 'ticket.owner' => '#{ticket.destroy! / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder ends with complex object' do
      let(:record) { { 'ticket' => '#{ticket.group}' }.to_json }
      let(:json_data) { { 'ticket' => '#{ticket.group / no such method}' } }

      it 'returns the placeholder reporting "no such method"' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains valid object and method' do
      let(:record) { { 'ticket.id' => '#{ticket.id}' }.to_json }
      let(:json_data) { { 'ticket.id' => ticket.id.to_s } }

      it 'returns the determined value' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains multiple valid object and method' do
      let(:record) do
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
        expect(generate).to eq(json_data)
      end
    end

    context 'when the placeholder contains multiple attributes' do
      let(:record) { { 'my_field' => '#{ticket.id} // #{ticket.group.name}' }.to_json }
      let(:json_data) do
        {
          'my_field' => "#{ticket.id} // #{ticket.group.name}",
        }
      end

      it 'returns the placeholder reporting "no such method"' do
        expect(generate).to eq(json_data)
      end
    end

    context "when the placeholder contains object 'notification'" do
      let(:record) { { 'body' => '#{notification}' }.to_json }
      let(:event)  do
        {
          type:      '',
          execution: 'job',
          changes:   {
            state: %w[open closed],
            group: %w[Users Customers],
          },
          user_id:   1,
        }
      end

      it 'returns a valid json with an notification factory generated message"' do
        expect(generate['body']).to include('open -> closed')
          .and include('Users -> Customers')
      end
    end

    context 'when the payload contains a complex structure' do
      let(:record) do
        {
          'current_user' => '#{current_user.fullname}',
          'ticket'       => {
            'id'      => '#{ticket.id}',
            'owner'   => '#{ticket.owner.fullname}',
            'group'   => '#{ticket.group.name}',
            'article' => {
              'id'          => '#{article.id}',
              'created_at'  => '#{article.created_at}',
              'subject'     => '#{article.subject}',
              'body'        => '#{article.body}',
              'attachments' => '#{article.attachments}'
            }
          }
        }.to_json
      end
      let(:json_data) do
        {
          'current_user' => '#{current_user / no such object}',
          'ticket'       => {
            'id'      => ticket.id.to_s,
            'owner'   => ticket.owner.fullname.to_s,
            'group'   => ticket.group.name.to_s,
            'article' => {
              'id'          => article.id.to_s,
              'created_at'  => article.created_at.to_s,
              'subject'     => article.subject.to_s,
              'body'        => article.body.to_s,
              'attachments' => '#{article.attachments / no such method}',
            }
          }
        }
      end

      it 'returns a valid JSON payload' do
        expect(generate).to eq(json_data)
      end
    end

    context 'when the replacement value contains double quotes' do
      let(:ticket)    { create(:ticket, title: 'Test "Title"') }
      let(:record)    { { 'ticket.title' => '#{ticket.title}' }.to_json }
      let(:json_data) { { 'ticket.title' => 'Test "Title"' } }

      it 'returns the determined value' do
        expect(generate).to eq(json_data)
      end
    end
  end
  # rubocop:enable Lint/InterpolationCheck
end
