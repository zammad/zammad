# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

        it 'skip activity check for editors when filtering by activity' do
          user = create(:admin)
          expect(described_class.check_active_unless_editor(user).count).to eq(2)
        end

        it 'check activity if user is not editor when filtering by activity' do
          user = create(:agent)
          expect(described_class.check_active_unless_editor(user)).to contain_exactly(knowledge_base)
        end

        it 'skip activity check for guests when filtering by activity' do
          expect(described_class.check_active_unless_editor(nil)).to contain_exactly(knowledge_base)
        end
      end
    end
  end

  context 'acceptable colors' do
    let(:allowed_values) { ['#aaa', '#ff0000', 'rgb(0,100,100)', 'hsl(0,100%,50%)'] }
    let(:not_allowed_values) { ['aaa', '#aa', '#ff000', 'rgb(0,100,100', 'def(0,100%,0.5)', 'test'] }

    it { is_expected.to allow_values(*allowed_values).for(:color_header) }
    it { is_expected.to allow_values(*allowed_values).for(:color_highlight) }
    it { is_expected.not_to allow_values(*not_allowed_values).for(:color_header) }
    it { is_expected.not_to allow_values(*not_allowed_values).for(:color_highlight) }
  end
end
