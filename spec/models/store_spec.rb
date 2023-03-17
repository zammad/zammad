# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# NOTE: This class uses custom .add & .remove methods
# to create and destroy records.
# This pattern is a strong candidate for refactoring
# to make use of Rails' native ActiveRecord + callbacks functionality.
RSpec.describe Store, type: :model do
  subject(:store) { create(:store, **attributes) }

  let(:attributes) do
    {
      object:      'Test',
      o_id:        1,
      data:        data,
      filename:    filename,
      preferences: preferences,
    }
  end

  let(:data)        { 'hello world' }
  let(:filename)    { 'test.txt' }
  let(:preferences) { {} }

  describe 'Class methods:' do
    describe '.add' do
      it 'creates a new Store record' do
        expect { create(:store, **attributes) }.to change(described_class, :count).by(1)
      end

      it 'returns the newly created Store record' do
        expect(create(:store, **attributes)).to eq(described_class.last)
      end

      it 'saves data to #content attribute' do
        expect { create(:store, **attributes) }
          .to change { described_class.last&.content }.to('hello world')
      end

      it 'saves filename to #filename attribute' do
        expect { create(:store, **attributes) }
          .to change { described_class.last&.filename }.to('test.txt')
      end

      it 'sets #provider attribute to "DB"' do
        expect { create(:store, **attributes) }
          .to change { described_class.last&.provider }.to('DB')
      end

      context 'with UTF-8 (non-ASCII) characters in text' do
        let(:data) { 'hello world äöüß' }

        it 'stores data as binary string to #content attribute' do
          expect { create(:store, **attributes) }
            .to change { described_class.last&.content }.to('hello world äöüß'.force_encoding('ASCII-8BIT'))
        end
      end

      context 'with UTF-8 (non-ASCII) characters in filename' do
        let(:filename) { 'testäöüß.txt' }

        it 'stores filename verbatim to #filename attribute' do
          expect { create(:store, **attributes) }
            .to change { described_class.last&.filename }.to('testäöüß.txt')
        end
      end

      context 'with binary data' do
        let(:data) { Rails.root.join('test/data/pdf/test1.pdf').binread }

        it 'stores data as binary string to #content attribute' do
          expect { create(:store, **attributes) }
            .to change { described_class.last&.content&.class }.to(String)
            .and change { described_class.last&.content }.to(data)
        end

        it 'saves filename to #filename attribute' do
          expect { create(:store, **attributes) }
            .to change { described_class.last&.filename }.to('test.txt')
        end

        it 'sets #provider attribute to "DB"' do
          expect { create(:store, **attributes) }
            .to change { described_class.last&.provider }.to('DB')
        end

        context 'when an identical file has been stored before under a different name' do
          before { create(:store, **attributes) }

          it 'creates a new (duplicate) described_class record' do
            expect { create(:store, **attributes.merge(filename: 'test-again.pdf')) }
              .to change(described_class, :count).by(1)
              .and change { described_class.last&.filename }.to('test-again.pdf')
              .and not_change { described_class.last&.content&.class }
              .and not_change { described_class.last&.content }
          end
        end
      end

      context 'with an image (jpeg/jpg/png)' do
        let(:data)        { Rails.root.join('test/data/upload/upload2.jpg').binread }
        let(:preferences) { { content_type: 'image/jpg' } }

        it 'generates previews' do
          create(:store, **attributes)

          expect(described_class.last.preferences)
            .to include(resizable: true, content_inline: true, content_preview: true)
        end

        context 'when system is in import mode' do
          before { Setting.set('import_mode', true) }

          it 'does not generate previews' do
            create(:store, **attributes)

            expect(described_class.last.preferences)
              .not_to include(resizable: true, content_inline: true, content_preview: true)
          end
        end
      end
    end

    describe '.remove' do
      before { create(:store, **attributes) }

      it 'destroys the specified Store record' do
        expect { described_class.remove(object: 'Test', o_id: 1) }
          .to change(described_class, :count).by(-1)
      end

      it 'destroys the associated Store::File record' do
        expect { described_class.remove(object: 'Test', o_id: 1) }
          .to change(described_class::File, :count).by(-1)
      end

      context 'with the same file stored under multiple o_ids' do
        before { create(:store, **attributes.merge(o_id: 2)) }

        it 'destroys only the specified Store record' do
          expect { described_class.remove(object: 'Test', o_id: 1) }
            .to change(described_class, :count).by(-1)
        end

        it 'does not destroy the associated Store::File record (because it is referenced by another Store)' do
          expect { described_class.remove(object: 'Test', o_id: 1) }
            .not_to change(Store::File, :count)
        end
      end

      context 'with multiple files stored under the same o_id' do
        before { create(:store, **attributes.merge(data: 'bar')) }

        it 'destroys all matching Store records' do
          expect { described_class.remove(object: 'Test', o_id: 1) }
            .to change(described_class, :count).by(-2)
        end

        it 'destroys all associated Store::File records' do
          expect { described_class.remove(object: 'Test', o_id: 1) }
            .to change(Store::File, :count).by(-2)
        end
      end
    end

    describe '.list' do
      let!(:store) do
        create(:store,
               object:   'Test',
               o_id:     1,
               data:     'hello world',
               filename: 'test.txt')
      end

      it 'runs a Store.where query for :object / :o_id parameters (:object is Store::Object association name)' do
        expect(described_class.list(object: 'Test', o_id: 1))
          .to eq([store])
      end

      context 'without a Store::Object name' do
        it 'returns an empty ActiveRecord::Relation' do
          expect(described_class.list(o_id: 1))
            .to be_an(ActiveRecord::Relation).and be_empty
        end
      end

      context 'without a #o_id' do
        it 'returns an empty ActiveRecord::Relation' do
          expect(described_class.list(object: 'Test'))
            .to be_an(ActiveRecord::Relation).and be_empty
        end
      end
    end
  end

  describe 'Instance methods:' do
    describe 'image previews (#content_inline / #content_preview)' do
      let(:attributes) do
        {
          object:      'Test',
          o_id:        1,
          data:        data,
          filename:    'test1.pdf',
          preferences: {
            content_type: content_type,
            content_id:   234,
          }
        }
      end

      let(:resized_inline_image) do
        File.binwrite(temp_file, store.content_inline)
        Rszr::Image.load(temp_file)
      end

      let(:resized_preview_image) do
        File.binwrite(temp_file.next, store.content_preview)
        Rszr::Image.load(temp_file.next)
      end

      let(:temp_file) { Tempfile.new.path }

      context 'with content_type: "text/plain"' do
        let(:content_type) { 'text/plain' }

        context 'and text content' do
          let(:data) { 'foo' }

          it 'cannot be resized (neither inlined nor previewed)' do
            expect { store.content_inline }
              .to raise_error('Inline content could not be generated.')

            expect { store.content_preview }
              .to raise_error('Content preview could not be generated.')

            expect(store.preferences)
              .to not_include(resizable: true)
              .and not_include(content_inline: true)
              .and not_include(content_preview: true)
          end
        end
      end

      context 'with content_type: "image/*"' do
        context 'and text content' do
          let(:content_type) { 'image/jpeg' }
          let(:data)         { 'foo' }

          it 'cannot be resized (neither inlined nor previewed)' do
            expect { store.content_inline }
              .to raise_error('Inline content could not be generated.')

            expect { store.content_preview }
              .to raise_error('Content preview could not be generated.')

            expect(store.preferences)
              .to not_include(resizable: true)
              .and not_include(content_inline: true)
              .and not_include(content_preview: true)
          end
        end

        context 'with image content (width > 1800px)' do
          context 'width <= 200px' do
            let(:content_type) { 'image/png' }
            let(:data) { Rails.root.join('test/data/image/1x1.png').binread }

            it 'cannot be resized (neither inlined nor previewed)' do
              expect { store.content_inline }
                .to raise_error('Inline content could not be generated.')

              expect { store.content_preview }
                .to raise_error('Content preview could not be generated.')

              expect(store.preferences)
                .to not_include(resizable: true)
                .and not_include(content_inline: true)
                .and not_include(content_preview: true)
            end
          end

          context '200px < width <= 1800px)' do
            let(:content_type) { 'image/png' }
            let(:data) { Rails.root.join('test/data/image/1000x1000.png').binread }

            it 'can be resized (previewed but not inlined)' do
              expect { store.content_inline }
                .to raise_error('Inline content could not be generated.')

              expect(resized_preview_image.width).to eq(200)

              expect(store.preferences)
                .to include(resizable: true)
                .and not_include(content_inline: true)
                .and include(content_preview: true)
            end
          end

          context '1800px < width' do
            let(:content_type) { 'image/jpeg' }
            let(:data) { Rails.root.join('test/data/upload/upload2.jpg').binread }

            it 'can be resized (inlined @ 1800px wide or previewed @ 200px wide)' do
              expect(resized_inline_image.width).to eq(1800)
              expect(resized_preview_image.width).to eq(200)

              expect(store.preferences)
                .to include(resizable: true)
                .and include(content_inline: true)
                .and include(content_preview: true)
            end

            context 'kind of wide/short: 8000x300' do
              let(:data) { Rails.root.join('test/data/image/8000x300.jpg').binread }

              it 'can be resized (inlined @ 1800px wide or previewed @ 200px wide)' do
                expect(resized_inline_image.width).to eq(1800)
                expect(resized_preview_image.width).to eq(200)

                expect(store.preferences)
                  .to include(resizable: true)
                  .and include(content_inline: true)
                  .and include(content_preview: true)
              end
            end

            context 'very wide/short: 4000x1; i.e., <= 6px vertically per 200px (preview) or 1800px (inline) horizontally' do
              let(:data) { Rails.root.join('test/data/image/4000x1.jpg').binread }

              it 'cannot be resized (neither inlined nor previewed)' do
                expect { store.content_inline }
                  .to raise_error('Inline content could not be generated.')

                expect { store.content_preview }
                  .to raise_error('Content preview could not be generated.')

                expect(store.preferences)
                  .to not_include(resizable: true)
                  .and not_include(content_inline: true)
                  .and not_include(content_preview: true)
              end
            end

            context 'very wide/short: 8000x25; i.e., <= 6px vertically per 200px (preview) or 1800px (inline) horizontally' do
              let(:data) { Rails.root.join('test/data/image/8000x25.jpg').binread }

              it 'cannot be resized (neither inlined nor previewed)' do
                expect { store.content_inline }
                  .to raise_error('Inline content could not be generated.')

                expect { store.content_preview }
                  .to raise_error('Content preview could not be generated.')

                expect(store.preferences)
                  .to not_include(resizable: true)
                  .and not_include(content_inline: true)
                  .and not_include(content_preview: true)
              end
            end
          end
        end
      end
    end
  end

  context 'when preferences exceed storage size' do

    let(:valid_entries) do
      {
        content_type: 'text/plain',
        content_id:   234,
      }
    end

    shared_examples 'keeps other entries' do

      context 'when other entries are present' do

        let(:preferences) do
          super().merge(valid_entries)
        end

        it 'keeps these entries' do
          expect(store.preferences).to include(valid_entries)
        end
      end
    end

    context 'when single content is oversized' do

      let(:preferences) do
        {
          oversized_content: '0' * 2500,
        }
      end

      it 'removes that entry' do
        expect(store.preferences).not_to have_key(:oversized_content)
      end

      include_examples 'keeps other entries'
    end

    context 'when the sum of multiple contents is oversized' do

      let(:preferences) do
        {
          oversized_content1: '0' * 2000,
          oversized_content2: '0' * 2000,
        }
      end

      it 'removes first entry' do
        expect(store.preferences).not_to have_key(:oversized_content1)
      end

      it 'keeps second entry' do
        expect(store.preferences).to have_key(:oversized_content2)
      end

      include_examples 'keeps other entries'
    end

    context 'when single key is oversized' do

      let(:oversized_key) { '0' * 2500 }
      let(:preferences) do
        {
          oversized_key => 'valid content',
        }
      end

      it 'removes that entry' do
        expect(store.preferences).not_to have_key(oversized_key)
      end

      include_examples 'keeps other entries'
    end

    context 'when the sum of multiple keys is oversized' do

      let(:oversized_key1) { '0' * 1500 }
      let(:oversized_key2) { '1' * 1500 }
      let(:preferences) do
        {
          oversized_key1 => 'valid content',
          oversized_key2 => 'valid content',
        }
      end

      it 'removes first entry' do
        expect(store.preferences).not_to have_key(oversized_key1)
      end

      it 'keeps second entry' do
        expect(store.preferences).to have_key(oversized_key2)
      end

      include_examples 'keeps other entries'
    end
  end
end
