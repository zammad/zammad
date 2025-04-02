# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::Article::Create, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  let(:ticket)  { create(:ticket, customer: create(:agent)) }
  let(:user)    { create(:agent, groups: [ticket.group]) }
  let(:payload) { { body: 'test' } }
  let(:article) { service.execute(article_data: payload, ticket: ticket) }

  describe '#execute' do
    it 'creates an article' do
      expect(article).to be_persisted
    end

    it 'creates an article even if contains wrong ticket id' do
      payload[:ticket_id] = 123_456

      expect(article).to be_persisted.and(have_attributes(ticket_id: ticket.id))
    end

    describe 'time accounting', :aggregate_failures do
      let(:time_accounting_enabled) { true }

      before do
        Setting.set('time_accounting', time_accounting_enabled)

        payload[:time_unit] = 60
      end

      it 'adds time accounting without type' do
        expect(article.ticket_time_accounting.time_unit).to be_present
        expect(article.ticket_time_accounting.type).to be_nil
      end

      context 'with accounting type' do
        let(:accounted_time_type) { create(:ticket_time_accounting_type) }

        before do
          payload[:accounted_time_type] = accounted_time_type
        end

        it 'adds time accounting with type' do
          expect(article.ticket_time_accounting.time_unit).to be_present
          expect(article.ticket_time_accounting.type).to eq(accounted_time_type)
        end

      end

      context 'when time accounting is not enabled' do
        let(:time_accounting_enabled) { false }

        it 'does not save article and raises error' do
          expect { article }
            .to raise_error(%r{Time Accounting is not enabled})
        end
      end
    end

    describe 'to and cc fields processing' do
      it 'translates to and cc fields from arrays to strings' do
        payload.merge!({ to: %w[a b], cc: %w[b c] })

        expect(article).to have_attributes(to: 'a, b', cc: 'b, c')
      end

      it 'handles string and nil values' do
        payload.merge!({ to: 'a,b', cc: nil })

        expect(article).to have_attributes(to: 'a,b', cc: '')
      end
    end

    describe 'sender processing' do
      context 'when user is agent' do
        it 'agent is set to agent' do
          expect(article.sender.name).to eq 'Agent'
        end

        it 'preserves original value if given' do
          payload[:sender] = 'Customer'

          expect(article.sender.name).to eq 'Customer'
        end
      end

      context 'when user is customer' do
        let(:user)   { ticket.customer }
        let(:ticket) { create(:ticket, customer: create(:customer)) }

        it 'ensures sender is set to customer' do
          expect(article.sender.name).to eq 'Customer'
        end
      end

      # Agent-Customer is incorrectly detected as Agent in a group he has no access to
      # https://github.com/zammad/zammad/issues/4649
      context 'when user is agent-customer' do
        let(:user) { ticket.customer }

        it 'ensures sender is set to customer' do
          expect(article.sender.name).to eq 'Agent'
        end
      end
    end

    describe 'processing for customer' do
      context 'when user is customer' do
        let(:user)   { ticket.customer }
        let(:ticket) { create(:ticket, customer: create(:customer)) }

        it 'ensures internal is false' do
          payload[:internal] = true

          expect(article.internal).to be_falsey
        end

        it 'changes type from web to note' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('note')
        end
      end

      # Agent-Customer is incorrectly detected as Agent in a group he has no access to
      # https://github.com/zammad/zammad/issues/4649
      context 'when user is agent-customer' do
        let(:user) { ticket.customer }

        it 'ensures internal is false' do
          payload[:internal] = false

          expect(article.internal).to be_falsey
        end

        it 'changes type from web to note' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('phone')
        end
      end

      context 'when user is agent' do
        it 'allows internal to be true' do
          payload[:internal] = true

          expect(article.internal).to be_truthy
        end

        it 'applies no changes to type' do
          payload[:type] = 'phone'

          expect(article.type.name).to eq('phone')
        end
      end
    end

    describe 'transforming attachments' do
      it 'adds attachments with inlines' do
        payload[:content_type] = 'text/html'
        payload[:body] = 'some body <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
  AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
  9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />'

        expect(article.attachments).to be_one
      end

      context 'when attachment is uploaded' do
        let(:form_id) { SecureRandom.uuid }
        let(:taskbar) { create(:taskbar, user_id: user.id, state: { form_id: }) }

        before do
          taskbar

          file_name    = 'file1.png'
          file_type    = 'image/png'
          file_content = Base64.strict_encode64('file1')

          UploadCache.new(form_id).tap do |cache|
            cache.add(
              data:          file_content,
              filename:      file_name,
              preferences:   { 'Content-Type' => file_type },
              created_by_id: 1,
            )
          end
        end

        it 'adds attachments with inlines and updates taskbar state', aggregate_failures: true do
          payload[:content_type] = 'text/html'
          payload[:attachments] = {
            files:   [],
            form_id:,
          }
          payload[:body] = "some body <img src='/api/v1/attachments/#{Store.last.id}'> alt='Red dot' />"

          expect(article.attachments).to be_one

          expect(taskbar.reload.state).to eq({})
        end
      end
    end

    describe 'mentions', aggregate_failures: true do
      def text_blob_with(user)
        "Lorem ipsum dolor <a data-mention-user-id='#{user.id}'>#{user.fullname}</a>"
      end

      let(:payload) { { body: body } }

      context 'when author can mention other users' do
        context 'when valid user is mentioned' do
          let(:body) { text_blob_with(user) }

          it 'create ticket with mentions' do
            expect { article }.to change(Mention, :count).by(1)
          end
        end

        context 'when user without access to the ticket is mentioned' do
          let(:body) { text_blob_with(create(:agent)) }

          it 'raises an error with one of mentions being invalid' do
            expect { article }
              .to raise_error(ActiveRecord::RecordInvalid)
            expect(Mention.count).to eq(0)
          end
        end
      end

      context 'when author does not have permissions to create mentions' do
        let(:user) { create(:customer) }
        let(:body) { text_blob_with(create(:agent, groups: [ticket.group])) }

        it 'raise an error if author does not have permissions to create mentions' do
          expect { article }
            .to raise_error(Pundit::NotAuthorizedError)
          expect(Mention.count).to eq(0)
        end
      end
    end
  end
end
