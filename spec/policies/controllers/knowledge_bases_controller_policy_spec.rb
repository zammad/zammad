# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::KnowledgeBasesControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBasesController }
  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  let(:params) { { id: knowledge_base.id } }

  # What a reader may see of the content is decided per record further down; these hand out the
  #   knowledge base itself and are open to any knowledge base access.
  let(:read_actions) { %i[show visible_ids preview] }

  context 'when user is editor' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(*%i[init update]) }
    it { is_expected.to permit_actions(*read_actions) }
  end

  context 'when user is reader' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_action(:init) }
    it { is_expected.to permit_actions(*read_actions) }
    it { is_expected.to forbid_action(:update) }
  end

  context 'when user is non-kb-user' do
    let(:user) { create(:customer) }

    # #init answers every authenticated user - KnowledgeBasesController#assets falls back to
    #   #public_assets for one without knowledge base access, and to nothing at all while
    #   `kb_active_publicly` is off.
    it { is_expected.to permit_action(:init) }
    it { is_expected.to forbid_actions(*read_actions) }
    it { is_expected.to forbid_action(:update) }
  end

  # There is only ever one knowledge base, created and removed through
  #   KnowledgeBase::ManageController under `admin.knowledge_base`. Neither action is routed here.
  describe 'creating and destroying' do
    let(:user) { create(:admin) }

    it { is_expected.to forbid_actions(:create, :destroy) }
  end

  # The regression this policy was rewritten for: it used to inherit
  #   `default_permit!('knowledge_base.*')` from a shared base policy, so any action added here
  #   without a predicate was reader-accessible by default. Every action is now named.
  describe 'the permission map' do
    let(:user) { create(:admin) }

    it 'has no default, so an ungated action raises rather than resolving to a permission' do
      expect(described_class.action_permissions_map.default).to be_nil
    end

    it 'names only the reads' do
      expect(described_class.action_permissions_map.keys).to match_array(read_actions.map { |action| :"#{action}?" })
    end

    it 'declares no entry for an action it also answers with a predicate', :aggregate_failures do
      described_class.action_permissions_map.each_key do |key|
        expect(described_class).not_to be_method_defined(key)
      end
    end
  end
end
