require 'rails_helper'

RSpec.describe Import::OTRS::Article do

  def creates_with(zammad_structure)
    expect(import_object).to receive(:new).with(zammad_structure).and_call_original
    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    expect(import_object).to receive(:find_by).and_return(existing_object)
    expect(existing_object).to receive(:update_attributes).with(zammad_structure)
    expect(import_object).not_to receive(:new)
    start_import_test
  end

  def load_article_json(file)
    json_fixture("import/otrs/article/#{file}")
  end

  let(:import_object) { Ticket::Article }
  let(:existing_object) { instance_double(import_object) }
  let(:start_import_test) { described_class.new(object_structure) }

  context 'customer phone' do

    let(:object_structure) { load_article_json('customer_phone_attachment') }
    let(:zammad_structure) {
      {
        created_by_id: '3',
        updated_by_id: 1,
        ticket_id:     '730',
        id:            '3970',
        body:          'test #3',
        from:          '"Betreuter Kunde" <kunde2@kunde.de>,',
        to:            'Postmaster',
        cc:            '',
        content_type:  'text/plain; charset=utf-8',
        subject:       'test #3',
        in_reply_to:   '',
        message_id:    '',
        references:    '',
        updated_at:    '2014-11-21 00:21:08',
        created_at:    '2014-11-21 00:17:41',
        type_id:       5,
        internal:      false,
        sender_id:     2
      }
    }

    it 'creates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      creates_with(zammad_structure)
    end

    it 'updates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      updates_with(zammad_structure)
    end
  end
end
