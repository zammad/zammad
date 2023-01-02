# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'jobs/trigger_webhook_job/record_payload/base_example'

RSpec.describe TriggerWebhookJob::RecordPayload::Ticket::Article do
  it_behaves_like 'TriggerWebhookJob::RecordPayload backend', :'ticket/article'

  describe '#generate' do
    subject(:generate) { described_class.new(record).generate }

    let(:resolved_associations) { described_class.const_get(:ASSOCIATIONS).map(&:to_s) }
    let(:record)                { create(:'ticket/article') }

    it "adds 'accounted_time' key" do
      expect(generate['accounted_time']).to be_zero
    end

    context 'when time accounting entry is present' do
      let!(:entry) { create(:ticket_time_accounting, ticket_id: record.ticket.id, ticket_article_id: record.id) }

      it "stores value as 'accounted_time' key" do
        expect(generate['accounted_time']).to eq(entry.time_unit)
      end
    end

    describe 'Webhhok transfers "accounted_time" of an article as integer instead of float/double #4127' do
      let(:entry) { create(:ticket_time_accounting, ticket_id: record.ticket.id, ticket_article_id: record.id, time_unit: 3.33) }

      it "stores value as 'accounted_time' key" do
        entry
        expect(generate['accounted_time']).to eq(3.33)
      end
    end

    context 'when Article has stored attachments' do

      before do
        create(:store,
               object:        record.class.name,
               o_id:          record.id,
               data:          'some content',
               filename:      'some_file.txt',
               preferences:   {
                 'Content-Type' => 'text/plain',
               },
               created_by_id: 1,)
      end

      it 'adds URLs to attachments' do
        expect(generate['attachments'].first['url']).to include(Setting.get('fqdn'))
      end
    end
  end
end
