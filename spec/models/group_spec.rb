# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/concerns/has_image_sanitized_note_examples'

RSpec.describe Group, type: :model do
  subject(:group) { create(:group) }

  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'

  describe 'audit log ignored attributes' do
    before { Setting.set('system_init_done', true) }

    it 'creates no audit log entry for note updates' do
      group

      expect { group.update!(note: 'Some updated note') }
        .not_to change(AuditLog.where(auditable_type: 'Group'), :count)
    end
  end

  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributes'
  it_behaves_like 'HasCollectionUpdate', collection_factory: :group
  it_behaves_like 'HasXssSanitizedNote', model_factory: :group
  it_behaves_like 'HasImageSanitizedNote', model_factory: :group
  it_behaves_like 'Association clears cache', association: :users
  it_behaves_like 'Association clears cache', association: :roles

  describe 'name compatibility layer' do
    context 'when creating a new group' do
      context 'with name attribute' do
        let(:name) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name' do
          expect(described_class.create(name: name)).to have_attributes(name_last: name)
        end

        context 'when using complete path' do
          let(:group1) { create(:group) }
          let(:group2) { create(:group, parent: group1) }
          let(:name)   { "#{group1.name_last}::#{group2.name_last}::#{Faker::Lorem.unique.word.capitalize}" }

          it 'sets parent_id attribute to guessed parent' do
            expect(described_class.create(name: name)).to have_attributes(parent_id: group2.id)
          end

          context 'when path is invalid' do
            let(:name) { Array.new(3) { Faker::Lorem.unique.word.capitalize }.join('::') }

            it 'raises validation error' do
              expect { described_class.create(name: name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name contains invalid path')
            end
          end
        end
      end

      context 'with name_last attribute' do
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end

      context 'with both name and name_last attribute' do
        let(:name)      { Faker::Lorem.unique.word.capitalize }
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name: name, name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end
    end

    context 'when updating an existing group' do
      let(:group) { create(:group) }

      context 'with name attribute' do
        let(:name)  { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name: name) if !defined?(skip_before)
        end

        it 'sets name_last attribute to name' do
          expect(group).to have_attributes(name_last: name)
        end

        context 'when using complete path' do
          let(:group1) { create(:group) }
          let(:group2) { create(:group, parent: group1) }
          let(:name)   { "#{group1.name_last}::#{group2.name_last}::#{Faker::Lorem.unique.word.capitalize}" }

          it 'sets parent_id attribute to guessed parent' do
            expect(group).to have_attributes(parent_id: group2.id)
          end

          context 'when path is invalid' do
            let(:name)        { Array.new(3) { Faker::Lorem.unique.word.capitalize }.join('::') }
            let(:skip_before) { true }

            it 'raises validation error' do
              expect { group.update!(name: name) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Name contains invalid path')
            end
          end
        end
      end

      context 'with name_last attribute' do
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name_last: name_last)
        end

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end

      context 'with both name and name_last attribute' do
        let(:name)      { Faker::Lorem.unique.word.capitalize }
        let(:name_last) { Faker::Lorem.unique.word.capitalize }

        before do
          group.update!(name: name, name_last: name_last)
        end

        it 'sets name_last attribute to name_last' do
          expect(described_class.create(name_last: name_last)).to have_attributes(name_last: name_last)
        end
      end
    end
  end

  describe 'tree related functions' do
    let!(:group_1)  { create(:group) }
    let!(:group_2)  { create(:group, parent: group_1) }
    let!(:group_31) { create(:group, parent: group_2) }
    let!(:group_32) { create(:group, parent: group_2) }
    let!(:group_4)  { create(:group, parent: group_31) }

    describe '#all_children' do
      it 'does return all children' do
        expect(group_1.all_children.sort).to eq([group_2, group_31, group_32, group_4].sort)
      end
    end

    describe '#all_parents' do
      it 'does return all parents ids' do
        expect(group_4.all_parents).to eq([group_31, group_2, group_1])
      end
    end

    describe '#depth' do
      it 'does return group depth' do
        expect(group_4.depth).to eq(3)
      end
    end

    describe '#check_max_depth (psql)' do
      def groups_with_depth(depth)
        groups = []

        groups << create(:group)
        groups += create_list(:group, depth - 1)

        groups.each_with_index do |group, idx|
          next if idx.zero?

          group.update!(parent: groups[idx - 1])
        end

        groups
      end

      let(:groups_1) { groups_with_depth(10) }
      let(:groups_2) { groups_with_depth(4) }

      let(:group_1_11) { create(:group, parent: groups_1.last) }
      let(:group_2_5)  { create(:group, parent: groups_2.last) }

      it 'does check depth on creation', :aggregate_failures do
        expect { groups_1 }.not_to raise_error
        expect { group_1_11 }.to raise_error(Exceptions::UnprocessableContent, 'This group exceeds the allowed nesting depth.')
        expect { group_2_5 }.not_to raise_error
      end

      it 'does check depth on tree merge', :aggregate_failures do
        expect do
          groups_1.last
          groups_2.last
        end.not_to raise_error

        expect { groups_2.last.update!(parent: groups_1.last) }.to raise_error(Exceptions::UnprocessableContent, 'This group exceeds the allowed nesting depth.')
      end

      it 'raises a separate error when the group itself would stay within bounds but a descendant would not' do
        # groups_2.first (depth 0) still has 3 levels of its own descendants below it; re-parenting
        # it under groups_1[6] (depth 6) keeps groups_2.first itself at depth 7 (within bounds), but
        # pushes its deepest descendant to depth 7 + 3 = 10, at the limit.
        expect { groups_2.first.update!(parent: groups_1[6]) }.to raise_error(
          Exceptions::UnprocessableContent, "This group's children would exceed the allowed nesting depth."
        )
      end
    end

    describe '#check_parent_not_in_subtree (psql)' do
      # The depth checks read the database, which still holds the old tree while validations run —
      # without an explicit subtree check, moving a group beneath its own descendant would pass
      # them and persist a parent_id cycle.
      it 'rejects moving a group beneath its own descendant' do
        expect { group_1.update!(parent: group_4) }.to raise_error(
          Exceptions::UnprocessableContent, 'This group cannot be moved into one of its children.'
        )
      end

      it 'rejects making a group its own parent' do
        expect { group_2.update!(parent: group_2) }.to raise_error(
          Exceptions::UnprocessableContent, 'This group cannot be moved into itself.'
        )
      end

      it 'does not persist a cycle when the move is rejected' do
        begin
          group_1.update!(parent: group_4)
        rescue Exceptions::UnprocessableContent
          # expected; only the persisted outcome matters here
        end

        expect(group_1.reload.parent_id).to be_nil
      end

      it 'still allows moving a group under an unrelated group' do
        expect { group_32.update!(parent: group_31) }.not_to raise_error
      end
    end

    describe '#check_parent_reaches_root (psql)' do
      # A pre-existing parent_id cycle (corrupt data) makes ancestry look finite and shallow to
      # #check_max_depth, since the walk's cycle guard just stops early — without this check,
      # groups could be attached beneath a cycle member, silently growing the corrupt component.
      let!(:ring_a) { create(:group) }
      let!(:ring_b) { create(:group, parent: ring_a) }

      before do
        ring_a.update_column(:parent_id, ring_b.id)
      end

      it 'rejects creating a group beneath a cycle member' do
        expect { create(:group, parent: ring_a) }.to raise_error(
          Exceptions::UnprocessableContent, 'The chosen parent group is part of a circular reference.'
        )
      end

      it 'rejects moving an existing group beneath a cycle member' do
        expect { group_1.update!(parent: ring_b) }.to raise_error(
          Exceptions::UnprocessableContent, 'The chosen parent group is part of a circular reference.'
        )
      end
    end

    describe '.unselectable_as_parent' do
      it 'returns no groups when none reach max_depth' do
        expect(described_class.unselectable_as_parent).to be_empty
      end

      it 'returns groups at max_depth - 1, whose children would already exceed max_depth, computed via a single recursive query from all roots' do
        # group_4 sits at depth 3 (group_1 -> group_2 -> group_31 -> group_4). Lowering max_depth
        # to 4 puts it (and only it) at the deepest valid level: still a legal group itself, but a
        # child of it would sit at depth 4 and be rejected by #check_max_depth — so it must not be
        # offered as a parent.
        allow(described_class).to receive(:max_depth).and_return(group_4.depth + 1)

        expect(described_class.unselectable_as_parent).to contain_exactly(group_4)
      end

      it 'agrees with #check_max_depth: attaching a child under a group at max_depth - 1 is rejected (psql)' do
        allow(described_class).to receive(:max_depth).and_return(group_4.depth + 1)

        expect { create(:group, parent: group_4) }.to raise_error(
          Exceptions::UnprocessableContent, 'This group exceeds the allowed nesting depth.'
        )
      end

      it 'also returns groups already deeper than the boundary, without walking past it' do
        # group_5 sits one level below group_4 (depth 4). It's only creatable at all because
        # max_depth is 10 at creation time; lowering it afterwards simulates a node that ended up
        # past the (now-current) boundary. The walk itself never visits group_4 or group_5 (it
        # stops at the boundary), but the complement still reports them as unselectable.
        group_5 = create(:group, parent: group_4)
        allow(described_class).to receive(:max_depth).and_return(group_4.depth + 1)

        expect(described_class.unselectable_as_parent).to contain_exactly(group_4, group_5)
      end

      it 'returns members of a parent_id cycle, which no walk from a root can reach (psql)' do
        # A cyclic component has no root above it, so the roots-downward walk never visits it —
        # only the complement catches it. Previously such groups were caught by per-group #depth
        # maxing out its bounded parent walk; they must stay unselectable as parents
        # (via CoreWorkflow::Custom::AdminGroupParentId).
        ring_a = create(:group)
        ring_b = create(:group, parent: ring_a)
        ring_a.update_column(:parent_id, ring_b.id)

        expect(described_class.unselectable_as_parent).to contain_exactly(ring_a, ring_b)
      end
    end

    describe 'recursion safety limit' do
      it 'caps every walk at HasRecursiveCteQuery::MAX_DEPTH_LIMIT even when no max_depth is given' do
        # Guards against a misconfigured or bypassed check (e.g. #check_max_depth disabled, or a
        # direct SQL edit) letting a large cyclic or pathological parent_id chain into the table:
        # even absent an explicit max_depth:, no walk should be able to visit the whole table.
        stub_const('HasRecursiveCteQuery::MAX_DEPTH_LIMIT', 1)

        expect(group_1.all_children.map(&:id)).to eq([group_2.id])
      end
    end

    context 'when parent_id contains a cycle (bypassing validations)' do
      # There is no DB constraint preventing a cycle in parent_id, only the depth check in
      # #check_max_depth, which is bypassed here via `update_column` to simulate e.g. a direct SQL
      # update or a race condition. #all_children and #all_parents must terminate safely (not hang
      # or raise SystemStackError) thanks to the cycle guard in their recursive CTEs.
      #
      # This makes group_1 a child of group_4, closing a loop:
      # group_1 -> group_4 -> group_31 -> group_2 -> group_1.
      before do
        group_1.update_column(:parent_id, group_4.id)
      end

      it 'all_children terminates and still returns every reachable node exactly once' do
        expect(Timeout.timeout(5) { group_2.all_children.map(&:id) }).to match_array(
          [group_1, group_31, group_32, group_4].map(&:id)
        )
      end

      it 'all_parents terminates, stopping as soon as the cycle is closed, and does not include group_1 among its own ancestors' do
        expect(Timeout.timeout(5) { group_1.all_parents.map(&:id) }).to eq(
          [group_4, group_31, group_2].map(&:id)
        )
      end
    end

    context 'when the whole tree is a closed loop (last item\'s parent redirected back to the first)' do
      # Minimal, non-branching ring with no root at all (every node has a parent), closed by
      # pointing the last one back at the first: ring_a -> ring_b -> ring_c -> ring_a. Kept
      # separate from group_1..group_4 above so every expected result is trivial to check by hand.
      let!(:ring_a) { create(:group) }
      let!(:ring_b) { create(:group, parent: ring_a) }
      let!(:ring_c) { create(:group, parent: ring_b) }

      before do
        ring_a.update_column(:parent_id, ring_c.id)
      end

      it 'all_children walks the ring exactly once and never includes the starting node itself' do
        result = Timeout.timeout(5) { ring_a.all_children.map(&:id) }

        expect(result).to eq([ring_b, ring_c].map(&:id))
      end

      it 'all_parents walks the ring exactly once and never includes the starting node itself' do
        result = Timeout.timeout(5) { ring_a.all_parents.map(&:id) }

        expect(result).to eq([ring_c, ring_b].map(&:id))
      end
    end
  end
end
