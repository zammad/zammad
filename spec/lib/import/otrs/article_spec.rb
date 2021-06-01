# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Article do

  def creates_with(zammad_structure)
    allow(import_object).to receive(:new).with(zammad_structure).and_call_original

    expect_any_instance_of(import_object).to receive(:save)
    expect_any_instance_of(described_class).to receive(:reset_primary_key_sequence)
    start_import_test
  end

  def updates_with(zammad_structure)
    allow(import_object).to receive(:find_by).and_return(existing_object)

    expect(existing_object).to receive(:update!).with(zammad_structure)
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
    let(:zammad_structure) do
      {
        created_by_id: '3',
        updated_by_id: 1,
        ticket_id:     '730',
        id:            '3970',
        body:          'test #3',
        from:          '"Betreuter Kunde" <kunde2@kunde.de>,',
        to:            'Postmaster',
        cc:            '',
        content_type:  'text/plain',
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
    end

    it 'creates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      creates_with(zammad_structure)
    end

    it 'updates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      updates_with(zammad_structure)
    end
  end

  context 'content type with comma' do

    let(:object_structure) { load_article_json('content_type_comma') }
    let(:zammad_structure) do
      {
        created_by_id: '3',
        updated_by_id: 1,
        ticket_id:     '730',
        id:            '3970',
        body:          'test #3',
        from:          '"Betreuter Kunde" <kunde2@kunde.de>,',
        to:            'Postmaster',
        cc:            '',
        content_type:  'text/plain',
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
    end

    it 'creates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      creates_with(zammad_structure)
    end

    it 'updates' do
      expect(Import::OTRS::Article::AttachmentFactory).to receive(:import)
      updates_with(zammad_structure)
    end
  end

  context 'no content type' do

    let(:object_structure) { load_article_json('no_content_type') }
    let(:zammad_structure) do
      {
        created_by_id: '1',
        updated_by_id: 1,
        ticket_id:     '999',
        id:            '999',
        body:          "Welcome!\n\nThank you for installing OTRS.\n\nYou will find updates and patches at http://www.otrs.com/open-source/.\nOnline documentation is available at http://doc.otrs.org/.\nYou can also use our mailing lists http://lists.otrs.org/\nor our forums at http://forums.otrs.org/\n\nRegards,\n\nThe OTRS Project\n",
        from:          'OTRS Feedback <feedback@otrs.org>',
        to:            'Your OTRS System <otrs@localhost>',
        cc:            nil,
        subject:       'Welcome to OTRS!',
        in_reply_to:   nil,
        message_id:    '<007@localhost>',
        references:    nil,
        updated_at:    '2014-06-24 09:32:14',
        created_at:    '2010-08-02 14:00:00',
        type_id:       1,
        internal:      false,
        sender_id:     2
      }
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end

  context 'no article body' do

    let(:object_structure) { load_article_json('customer_phone_no_body') }
    let(:zammad_structure) do
      {
        created_by_id: '3',
        updated_by_id: 1,
        ticket_id:     '730',
        id:            '3970',
        body:          '',
        from:          '"Betreuter Kunde" <kunde2@kunde.de>,',
        to:            'Postmaster',
        cc:            '',
        content_type:  'text/plain',
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
    end

    it 'creates' do
      creates_with(zammad_structure)
    end

    it 'updates' do
      updates_with(zammad_structure)
    end
  end
end
