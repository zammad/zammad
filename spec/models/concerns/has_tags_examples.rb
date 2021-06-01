# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

  describe '#tag_list' do
    it 'delegates to Tag.tag_list' do
      expect(Tag)
        .to receive(:tag_list)
        .with(object: described_class.name,
              o_id:   subject.id)

      subject.tag_list
    end
  end
end
