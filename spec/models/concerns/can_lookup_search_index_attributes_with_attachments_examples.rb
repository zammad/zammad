# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'CanLookupSearchIndexAttributesWithAttachments' do
  subject { create(described_class.name.underscore) }

  describe '#search_index_attachments_lookup' do
    let(:attachment_1) do
      create(:store,
             object:   described_class.name,
             o_id:     subject.id,
             data:     'a' * ((1024**2) * 2.4), # with 2.4 mb
             filename: 'test.TXT')
    end

    let(:attachment_2) do
      create(:store,
             object:   described_class.name,
             o_id:     subject.id,
             data:     'Some content',
             filename: 'example.txt')
    end

    let(:attachment_3) do
      create(:store,
             object:   described_class.name,
             o_id:     subject.id,
             data:     'Some content',
             filename: 'fancy.exe')
    end

    before do
      attachment_1
      attachment_2
      attachment_3
    end

    context 'when an attachment is ignored due to file type' do
      it 'does not include the attachment in the results' do
        expect(subject.search_index_attachments_lookup(0)).to include(
          include('_name' => 'example.txt'),
          include('_name' => 'test.TXT'),
        ).and not_include(
          include('_name' => 'fancy.exe'),
        )
      end
    end

    context 'when an attachment is too big' do
      before do
        Setting.set('es_attachment_max_size_in_mb', 2)
      end

      it 'does not include the large attachment in the results' do
        expect(subject.search_index_attachments_lookup(0)).to include(
          include('_name' => 'example.txt'),
        ).and not_include(
          include('_name' => 'test.TXT'),
        )
      end
    end

    context 'when adding the attachment would exceed the total payload size limit' do
      context 'when a large attachment exceeds the total payload size limit' do
        before do
          Setting.set('es_total_max_size_in_mb', 2)
        end

        it 'does not include the large attachment in the results' do
          expect(subject.search_index_attachments_lookup(0)).to include(
            include('_name' => 'example.txt'),
          ).and not_include(
            include('_name' => 'test.TXT'),
          )
        end
      end

      context 'when the existing payload size is already close to the limit' do
        before do
          Setting.set('es_total_max_size_in_mb', 3)
        end

        it 'does not include the attachment that would exceed the limit in the results' do
          expect(subject.search_index_attachments_lookup(1024**2)).to include(
            include('_name' => 'example.txt'),
          ).and not_include(
            include('_name' => 'test.TXT'),
            include('_name' => 'fancy.exe')
          )
        end
      end

      context 'when multiple individually valid attachments exceed the total payload size limit together' do
        let(:attachment_1) do
          create(:store,
                 object:   described_class.name,
                 o_id:     subject.id,
                 data:     'a' * ((1024**2) * 0.6),
                 filename: 'first.txt')
        end

        let(:attachment_2) do
          create(:store,
                 object:   described_class.name,
                 o_id:     subject.id,
                 data:     'b' * ((1024**2) * 0.6),
                 filename: 'second.txt')
        end

        let(:attachment_3) do
          create(:store,
                 object:   described_class.name,
                 o_id:     subject.id,
                 data:     'Some content',
                 filename: 'third.txt')
        end

        before do
          Setting.set('es_total_max_size_in_mb', 1)
        end

        it 'does not include attachments that do not fit into the cumulative payload limit is reached' do
          expect(subject.search_index_attachments_lookup(0)).to include(
            include('_name' => 'first.txt'),
            include('_name' => 'third.txt'),
          ).and not_include(
            include('_name' => 'second.txt'),
          )
        end
      end
    end
  end
end
