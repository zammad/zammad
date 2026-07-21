# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase, type: :model do
  subject(:knowledge_base) { create(:knowledge_base) }

  # make sure there's no KBs from seed data
  before { described_class.all.each(&:full_destroy!) }

  include_context 'factory'

  it_behaves_like 'ChecksKbClientNotification'

  it { is_expected.to validate_presence_of(:color_highlight) }
  it { is_expected.to validate_presence_of(:color_header) }
  it { is_expected.to validate_presence_of(:iconset).with_message(%r{}) }
  it { is_expected.to validate_inclusion_of(:iconset).in_array(KnowledgeBase::ICONSETS) }
  it { is_expected.to validate_inclusion_of(:category_layout).in_array(KnowledgeBase::LAYOUTS) }
  it { is_expected.to validate_inclusion_of(:homepage_layout).in_array(KnowledgeBase::LAYOUTS) }

  describe 'audit log' do
    before { Setting.set('system_init_done', true) }

    let(:audit_logs) { AuditLog.where(auditable_type: described_class.name) }

    context 'when knowledge base is created' do
      it 'creates an audit log record' do
        expect { knowledge_base }.to change(audit_logs.where(action_type: 'create'), :count).by(1)
      end

      it 'records the default translation title as auditable name' do
        expect(audit_logs.find_by(action_type: 'create', auditable_id: knowledge_base.id).auditable_name)
          .to eq(knowledge_base.translation_primary.title)
      end
    end

    context 'when knowledge base is updated' do
      it 'creates an audit log record' do
        knowledge_base

        expect { knowledge_base.update!(color_highlight: '#BBB') }
          .to change(audit_logs.where(action_type: 'update', auditable_id: knowledge_base.id), :count).by(1)
      end
    end

    context 'when knowledge base is fully destroyed' do
      it 'creates only a single destroy entry without entries for the destroyed locales' do
        knowledge_base

        expect { knowledge_base.full_destroy! }
          .to change(AuditLog.where(action_type: 'destroy'), :count).by(1)
      end

      it 'records the translation title as auditable name' do
        title = knowledge_base.translation_primary.title

        knowledge_base.full_destroy!

        expect(audit_logs.find_by(action_type: 'destroy', auditable_id: knowledge_base.id).auditable_name)
          .to eq(title)
      end
    end
  end

  context 'activation' do
    it 'on by default' do
      expect(knowledge_base).to be_active
    end

    it 'switcing off changes kb_active setting to false' do
      knowledge_base # trigger KB creation to set initial setting value
      expect { knowledge_base.update(active: false) }.to change { Setting.get('kb_active') }.from(true).to(false)
    end

    context 'with inactive' do
      let!(:knowledge_base_inactive) { create(:knowledge_base, active: false) }

      it 'switching on changes kb_active setting to true' do
        expect { knowledge_base_inactive.update(active: true) }.to change { Setting.get('kb_active') }.from(false).to(true)
      end

      context 'including active' do
        before { knowledge_base }

        it 'ensure 2 knowledge bases are created' do
          expect(described_class.count).to eq(2)
        end

        it 'filter by activity' do
          expect(described_class.active).to contain_exactly(knowledge_base)
        end
      end
    end
  end

  context 'acceptable colors' do
    let(:allowed_values)     { ['#aaa', '#ff0000', 'rgb(0,100,100)', 'hsl(0,100%,50%)'] }
    let(:not_allowed_values) { ['aaa', '#aa', '#ff000', 'rgb(0,100,100', 'def(0,100%,0.5)', 'test'] }

    %i[color_header color_header_link color_highlight].each do |attr|
      it { is_expected.to allow_values(*allowed_values).for(attr) }
      it { is_expected.not_to allow_values(*not_allowed_values).for(attr) }
    end
  end

  describe '#full_destroy!' do
    let(:knowledge_base) { create(:kb_category_with_tree).knowledge_base }

    before { knowledge_base }

    it 'destroys every category in a multi-level tree' do
      expect { knowledge_base.full_destroy! }
        .to change(KnowledgeBase::Category, :count).by(-knowledge_base.categories.count)
    end
  end

  context 'with a category tree at the deepest allowed nesting (psql)' do
    # The recursive CTE walks are capped at HasRecursiveCteQuery::MAX_DEPTH_LIMIT, which must
    # cover every tree the business limit permits — a cap below it silently loses categories in
    # traversal, falsely fails the circular-reference validation one level further down, and
    # makes #full_destroy! raise ActiveRecord::DeleteRestrictionError.
    let(:depth) { KnowledgeBase::Category.max_depth }

    let!(:chain) do
      [create(:knowledge_base_category, knowledge_base: knowledge_base)].tap do |categories|
        (depth - 1).times do
          child = build(:knowledge_base_category, knowledge_base: knowledge_base)
          child.parent = categories.last
          child.save!(validate: false) # skip validations to build the fixture fast
          categories << child
        end
      end
    end

    it 'traverses, validates against, and destroys the whole tree', :aggregate_failures do
      expect(chain.first.self_with_children.count).to eq(depth)

      fresh = build(:knowledge_base_category, knowledge_base: knowledge_base)
      fresh.parent = chain.last
      expect(fresh.tap(&:valid?).errors[:parent_id])
        .to contain_exactly('would exceed the allowed nesting depth') # depth limit, NOT a false circular-reference error

      expect { knowledge_base.full_destroy! }.to change(KnowledgeBase::Category, :count).by(-depth)
    end
  end
end
