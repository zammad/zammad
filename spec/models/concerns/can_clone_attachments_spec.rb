# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CanCloneAttachments do
  let(:image_data)         { Rails.root.join('test/data/image/1x1.png').binread }
  let(:target_object_type) { 'UploadCache' }
  let(:target_object_id)   { SecureRandom.uuid }
  let(:article)            { create(:ticket_article, content_type: 'text/html', body: '<img src="cid:first@example.com">') }

  describe '#clone_attachments' do
    context 'without options (default mode)' do
      context 'when an inline image shares filename and size with an unrelated existing attachment, but has a different Content-ID' do
        let(:unrelated_existing) do
          create(:store, object: target_object_type, o_id: target_object_id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-ID' => 'unrelated@example.com', 'Content-Disposition' => 'inline' })
        end

        let(:inline_attachment) do
          create(:store, object: article.class.name, o_id: article.id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-ID' => 'first@example.com', 'Content-Disposition' => 'inline' })
        end

        before do
          unrelated_existing
          inline_attachment
        end

        it 'clones the attachment despite the filename/size collision' do
          cloned = UserInfo.with_user_id(1) { article.clone_attachments(target_object_type, target_object_id) }

          expect(cloned.map { |elem| elem.preferences['Content-ID'] }).to include('first@example.com')
        end
      end

      context 'when an attachment with the same filename, size and Content-ID already exists' do
        let(:existing) do
          create(:store, object: target_object_type, o_id: target_object_id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-ID' => 'first@example.com', 'Content-Disposition' => 'inline' })
        end

        let(:inline_attachment) do
          create(:store, object: article.class.name, o_id: article.id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-ID' => 'first@example.com', 'Content-Disposition' => 'inline' })
        end

        before do
          existing
          inline_attachment
        end

        it 'does not clone the duplicate attachment (unchanged behavior)' do
          cloned = UserInfo.with_user_id(1) { article.clone_attachments(target_object_type, target_object_id) }

          expect(cloned).to be_empty
        end
      end

      context 'with a plain attachment (no Content-ID) that shares filename and size with an existing one' do
        let(:existing) do
          create(:store, object: target_object_type, o_id: target_object_id, filename: 'report.pdf', data: 'some content')
        end

        let(:plain_attachment) do
          create(:store, object: article.class.name, o_id: article.id, filename: 'report.pdf', data: 'some content')
        end

        before do
          existing
          plain_attachment
        end

        it 'does not clone the duplicate attachment (unchanged behavior)' do
          cloned = UserInfo.with_user_id(1) { article.clone_attachments(target_object_type, target_object_id) }

          expect(cloned).to be_empty
        end
      end
    end

    context 'with only_inline_attachments: true' do
      let(:article) { create(:ticket_article, content_type: 'text/html', body: '<img src="cid:first@example.com"><img src="cid:second@example.com">') }

      let(:unrelated_existing) do
        create(:store, object: target_object_type, o_id: target_object_id, filename: 'image1.png', data: image_data,
                        preferences: { 'Content-ID' => 'unrelated@example.com', 'Content-Disposition' => 'inline' })
      end

      let(:first_inline_attachment) do
        create(:store, object: article.class.name, o_id: article.id, filename: 'image1.png', data: image_data,
                        preferences: { 'Content-ID' => 'first@example.com', 'Content-Disposition' => 'inline' })
      end

      let(:second_inline_attachment) do
        create(:store, object: article.class.name, o_id: article.id, filename: 'image1.png', data: image_data,
                        preferences: { 'Content-ID' => 'second@example.com', 'Content-Disposition' => 'inline' })
      end

      before do
        unrelated_existing
        first_inline_attachment
        second_inline_attachment
      end

      it 'clones every inline image referenced in the body, even when filename and size collide' do
        cloned = UserInfo.with_user_id(1) { article.clone_attachments(target_object_type, target_object_id, only_inline_attachments: true) }

        expect(cloned.map { |elem| elem.preferences['Content-ID'] }).to contain_exactly('first@example.com', 'second@example.com')
      end
    end
  end
end
