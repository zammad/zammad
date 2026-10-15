# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::UploadCache::Add do
  subject(:service_result) { described_class.with_current_user(user).execute(form_id:, files:) }

  let(:user)    { create(:agent, groups: [article.ticket.group]) }
  let(:form_id) { SecureRandom.uuid }
  let(:article) { create(:ticket_article, :inbound_email) }
  let(:image)   { Rails.root.join('test/data/image/1x1.png').binread }
  let(:attachment) do
    create(:store,
           object:      'Ticket::Article',
           o_id:        article.id,
           data:        image,
           filename:    'screenshot.png',
           preferences: { 'Mime-Type' => 'image/png', 'Content-ID' => 'image.1@example.com', 'Content-Disposition' => 'inline' })
  end

  describe '#execute' do
    context 'with file content' do
      let(:files) { [{ name: 'test.txt', type: 'text/plain', content: 'some content', inline: false }] }

      it 'adds the file to the upload cache of the form' do
        expect(service_result).to contain_exactly(
          have_attributes(
            store_object:  have_attributes(name: 'UploadCache'),
            o_id:          form_id,
            filename:      'test.txt',
            content:       'some content',
            preferences:   { 'Content-Type' => 'text/plain' },
            created_by_id: user.id,
          )
        )
      end

      context 'when it is inline' do
        let(:files) { [{ name: 'image.png', type: 'image/png', content: image, inline: true }] }

        it 'marks the file as inline' do
          expect(service_result.first).to be_inline
        end
      end
    end

    context 'with an attachment to copy' do
      let(:files) { [{ attachment:, inline: true }] }

      it 'adds a copy with the name, type and content of the attachment' do
        expect(service_result).to contain_exactly(
          have_attributes(
            store_object:  have_attributes(name: 'UploadCache'),
            o_id:          form_id,
            filename:      'screenshot.png',
            content:       image,
            created_by_id: user.id,
          )
        )
      end

      it 'marks the copy as inline without taking over the Content-ID' do
        expect(service_result.first.preferences).to eq('Content-Type' => 'image/png', 'Content-Disposition' => 'inline')
      end

      it 'leaves the attachment untouched' do
        expect { service_result }.not_to change { attachment.reload.attributes }
      end

      it 'keeps the copy when the article of the attachment is deleted' do
        copy = service_result.first
        article.destroy!

        expect(Store.find(copy.id).content).to eq(image)
      end

      context 'when a name and type are given' do
        let(:files) { [{ attachment:, name: 'renamed.png', type: 'image/x-png' }] }

        it 'uses them instead of the ones of the attachment' do
          expect(service_result.first).to have_attributes(filename: 'renamed.png', preferences: { 'Content-Type' => 'image/x-png' })
        end
      end

      context 'when the user has no access to the attachment' do
        let(:user)  { create(:agent) }
        let(:files) { [{ name: 'test.txt', content: 'some content' }, { attachment: }] }

        it 'fails with Pundit error and adds nothing' do
          expect { service_result }
            .to raise_error(Pundit::NotAuthorizedError)
            .and not_change { UploadCache.new(form_id).attachments(created_by_id: nil).count }
        end
      end
    end

    context 'with a file that cannot be stored' do
      let(:files) { [{ name: 'test.txt', content: 'some content' }, { content: 'no name' }] }

      it 'adds none of the files' do
        expect { service_result }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and not_change { UploadCache.new(form_id).attachments(created_by_id: nil).count }
      end
    end

    context 'with several files' do
      let(:files) { [{ attachment: }, { name: 'test.txt', content: 'some content' }] }

      it 'returns them in the given order' do
        expect(service_result.map(&:filename)).to eq(['screenshot.png', 'test.txt'])
      end
    end
  end

  context 'without a current user' do
    let(:files) { [{ name: 'test.txt', content: 'some content' }] }

    it 'is rejected' do
      expect { described_class.execute(form_id:, files:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
