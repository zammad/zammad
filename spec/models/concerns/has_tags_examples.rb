# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasTags' do
  subject { create(described_class.name.underscore) }

  describe '#tag_add' do
    let(:item_name) { 'foo' }

    it 'delegates to Tag.tag_add' do
      expect(Tag)
        .to receive(:tag_add)
        .with(object:        described_class.name,
              o_id:          subject.id,
              item:          item_name,
              created_by_id: nil)

      subject.tag_add(item_name)
    end

    it 'optionally accepts a current_user_id argument' do
      expect(Tag)
        .to receive(:tag_add)
        .with(object:        described_class.name,
              o_id:          subject.id,
              item:          item_name,
              created_by_id: 1)

      subject.tag_add(item_name, 1)
    end
  end

  describe '#tag_remove' do
    let(:item_name) { 'foo' }

    it 'delegates to Tag.tag_remove' do
      expect(Tag)
        .to receive(:tag_remove)
        .with(object:        described_class.name,
              o_id:          subject.id,
              item:          item_name,
              created_by_id: nil)

      subject.tag_remove(item_name)
    end

    it 'optionally accepts a current_user_id argument' do
      expect(Tag)
        .to receive(:tag_remove)
        .with(object:        described_class.name,
              o_id:          subject.id,
              item:          item_name,
              created_by_id: 1)

      subject.tag_remove(item_name, 1)
    end
  end

  describe '#tag_update' do
    let(:items) { %w[foo bar] }

    it 'delegates to Tag.tag_update' do
      expect(Tag)
        .to receive(:tag_update)
        .with(object:        described_class.name,
              o_id:          subject.id,
              items:         items,
              created_by_id: nil)

      subject.tag_update(items)
    end

    it 'optionally accepts a current_user_id argument' do
      expect(Tag)
        .to receive(:tag_update)
        .with(object:        described_class.name,
              o_id:          subject.id,
              items:         items,
              created_by_id: 1)

      subject.tag_update(items, 1)
    end
  end

  describe '#tag_list' do
    it 'delegates to Tag.tag_list' do
      expect(Tag)
        .to receive(:tag_list)
        .with(object: described_class.name,
              o_id:   subject.id)

      subject.tag_list
    end
  end

  shared_context 'with subject and another object being tagged', current_user_id: 1 do
    before do
      subject.tag_add(tag)
      Tag.tag_add(object: 'AnotherObject', o_id: 123, item: tag)
    end

    let(:tag) { 'tag_name' }
  end

  describe '.tag_references' do
    include_context 'with subject and another object being tagged' do
      it 'returns reference to subject' do
        expect(described_class.tag_references(tag)).to match_array [subject.id]
      end

      it 'does not return reference to subject when called with other tag' do
        expect(described_class.tag_references('other')).to be_blank
      end
    end
  end

  describe '.tag_objects' do
    include_context 'with subject and another object being tagged' do
      it 'returns subject' do
        expect(described_class.tag_objects(tag)).to match_array [subject]
      end

      it 'does not return subject when called with other tag' do
        expect(described_class.tag_objects('other')).to be_blank
      end
    end
  end
end
