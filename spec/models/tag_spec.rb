# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject(:tag) { create(:tag) }

  shared_examples 'tag adding' do
    context 'when a Tag::Object does not exist for the given class' do
      it 'creates it and assigns it to a new Tag' do
        expect { described_class.tag_add(object: 'Foo', item: 'bar', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and change { Tag::Object.exists?(name: 'Foo') }.to(true)
          .and change { described_class.last&.tag_object&.name }.to('Foo')
      end
    end

    context 'when a Tag::Object already exists for the given class' do
      let!(:tag_object) { Tag::Object.find_or_create_by(name: 'Ticket') }

      it 'assigns it to a new Tag' do
        expect { described_class.tag_add(object: 'Ticket', item: 'foo', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and not_change(Tag::Object, :count)
          .and change { described_class.last&.tag_object&.name }.to('Ticket')
      end
    end

    context 'when a Tag::Item does not exist with the given name' do
      it 'creates it and assigns it to a new Tag' do
        expect { described_class.tag_add(object: 'Ticket', item: 'foo', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and change { Tag::Item.exists?(name: 'foo') }.to(true)
          .and change { described_class.last&.tag_item&.name }.to('foo')
      end

      it 'strips trailing/leading whitespace' do
        expect { described_class.tag_add(object: 'Ticket', item: '  foo ', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and change { Tag::Item.exists?(name: 'foo') }.to(true)
          .and change { described_class.last&.tag_item&.name }.to('foo')
      end

      context 'and the name contains 8-bit Unicode characters' do
        it 'creates it and assigns it to a new Tag' do
          expect { described_class.tag_add(object: 'Ticket', item: 'fooöäüß', o_id: 1, created_by_id: 1) }
            .to change(described_class, :count).by(1)
            .and change { Tag::Item.exists?(name: 'fooöäüß') }.to(true)
            .and change { described_class.last&.tag_item&.name }.to('fooöäüß')
        end
      end

      context 'but the name is a case-sensitive variant of an existing Tag::Item', if: Rails.application.config.db_case_sensitive do
        let!(:tag_item) { create(:'tag/item', name: 'foo') }

        it 'creates it and assigns it to a new Tag' do
          expect { described_class.tag_add(object: 'Ticket', item: 'FOO', o_id: 1, created_by_id: 1) }
            .to change(described_class, :count).by(1)
            .and change { Tag::Item.pluck(:name).include?('FOO') }.to(true) # .exists?(name: 'FOO') fails on MySQL
            .and change { described_class.last&.tag_item&.name }.to('FOO')
        end
      end
    end

    context 'when a Tag::Item already exists with the given name' do
      let!(:tag_item) { create(:'tag/item', name: 'foo') }

      it 'assigns it to a new Tag' do
        expect { described_class.tag_add(object: 'Ticket', item: 'foo', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and not_change(Tag::Item, :count)
          .and change { described_class.last&.tag_item&.name }.to('foo')
      end

      it 'strips leading/trailing whitespace' do
        expect { described_class.tag_add(object: 'Ticket', item: '  foo ', o_id: 1, created_by_id: 1) }
          .to change(described_class, :count).by(1)
          .and not_change(Tag::Item, :count)
          .and change { described_class.last&.tag_item&.name }.to('foo')
      end
    end

    context 'when a Tag already exists for the specified record with the given name' do
      let!(:tag) { create(:tag, o: Ticket.first, tag_item: tag_item) }
      let(:tag_item) { create(:'tag/item', name: 'foo') }

      it 'does not create any records' do
        expect { described_class.tag_add(object: 'Ticket', item: 'foo', o_id: Ticket.first.id, created_by_id: 1) }
          .to not_change(described_class, :count)
          .and not_change(Tag::Item, :count)
      end
    end
  end

  describe '.tag_add' do
    it 'touches the target object' do
      expect { described_class.tag_add(object: 'Ticket', item: 'foo', o_id: Ticket.first.id, created_by_id: 1) }
        .to change { Ticket.first.updated_at }
    end

    include_examples 'tag adding'
  end

  describe '.tag_remove' do
    it 'touches the target object' do
      expect { described_class.tag_remove(object: 'Ticket', item: 'foo', o_id: Ticket.first.id, created_by_id: 1) }
        .to change { Ticket.first.updated_at }
    end

    context 'when a matching Tag exists' do
      let!(:tag) { create(:tag, o: Ticket.first, tag_item: tag_item) }
      let(:tag_item) { create(:'tag/item', name: 'foo') }

      it 'destroys the Tag' do
        expect { described_class.tag_remove(object: 'Ticket', o_id: Ticket.first.id, item: 'foo') }
          .to change(described_class, :count).by(-1)
      end
    end

    context 'when no matching Tag exists' do
      it 'makes no changes' do
        expect { described_class.tag_remove(object: 'Ticket', o_id: Ticket.first.id, item: 'foo') }
          .not_to change(described_class, :count)
      end
    end
  end

  describe '.tag_update' do
    let(:ticket) { Ticket.first }

    it 'touches the target object' do
      expect { described_class.tag_update(object: 'Ticket', items: ['foo'], o_id: ticket.id, created_by_id: 1) }
        .to change { ticket.reload.updated_at }
    end

    it 'adds new tags' do
      described_class.tag_update(object: 'Ticket', items: %w[foo bar], o_id: ticket.id, created_by_id: 1)
      expect(ticket.tag_list).to match_array %w[foo bar]
    end

    context 'with existing tags' do
      before do
        %w[tag1 tag2].each { |elem| ticket.tag_add elem, 1 }
      end

      it 'make no changes if given tags match existing tags' do
        described_class.tag_update(object: 'Ticket', items: %w[tag1 tag2], o_id: ticket.id, created_by_id: 1)

        expect(ticket.tag_list).to match_array %w[tag1 tag2]
      end

      it 'removes no longer present tags' do
        described_class.tag_update(object: 'Ticket', items: ['tag1'], o_id: ticket.id, created_by_id: 1)

        expect(ticket.tag_list).to match_array ['tag1']
      end

      it 'adds and removes no longer present tags at once' do
        described_class.tag_update(object: 'Ticket', items: %w[tag1 foo], o_id: ticket.id, created_by_id: 1)

        expect(ticket.tag_list).to match_array %w[tag1 foo]
      end
    end

    include_examples 'tag adding'
  end

  describe '.tag_list' do
    context 'with ASCII item names' do
      before { items.map { |i| create(:tag, tag_item: i, o: Ticket.first) } }

      let(:items) do
        [
          create(:'tag/item', name: 'foo'),
          create(:'tag/item', name: 'bar'),
          create(:'tag/item', name: 'BAR'),
        ]
      end

      it 'returns all tag names (case-sensitive) for a given record' do
        expect(described_class.tag_list(object: 'Ticket', o_id: Ticket.first.id))
          .to match_array(%w[foo bar BAR])
      end
    end

    context 'with Unicode (8-bit) item names' do
      before { items.map { |i| create(:tag, tag_item: i, o: Ticket.first) } }

      let(:items) do
        [
          create(:'tag/item', name: 'fooöäüß'),
          create(:'tag/item', name: 'baröäüß'),
          create(:'tag/item', name: 'BARöäüß'),
        ]
      end

      it 'returns all tag names (case-sensitive) for a given record' do
        expect(described_class.tag_list(object: 'Ticket', o_id: Ticket.first.id))
          .to match_array(%w[fooöäüß baröäüß BARöäüß])
      end
    end
  end

  describe '.tag_references' do
    context 'with objects with a tag', current_user_id: 1 do
      before do
        [object_1, object_2].each do |elem|
          described_class.tag_add object: elem.class.name, o_id: elem.id, item: tag
        end
      end

      let(:object_1) { create(:ticket) }
      let(:object_2) { create(:knowledge_base_answer) }
      let(:tag)      { 'foo' }

      it 'returns references' do
        expect(described_class.tag_references(tag: tag)).to match_array [
          [object_1.class.name, object_1.id],
          [object_2.class.name, object_2.id]
        ]
      end

      it 'returns references for the given object type' do
        expect(described_class.tag_references(tag: tag, object: 'Ticket')).to match_array [
          [object_1.class.name, object_1.id]
        ]
      end
    end

  end
end
