# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::KnowledgeBase::ManageControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::ManageController }
  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  let(:params) { { id: knowledge_base.id } }

  # Every action KnowledgeBase::ManageController answers. `resources :manage` also routes `index`,
  #   `new` and `edit`, which it does not implement.
  let(:actions) do
    %i[init show create update destroy server_snippets activate deactivate update_menu_items]
  end

  context 'when user is admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(*actions) }
  end

  # The regression this policy was rewritten for. It used to inherit
  #   `permit! %i[create update destroy], to: 'knowledge_base.editor'` from a shared base policy,
  #   and its own `default_permit!` could not displace those keys - a Hash key beats a Hash
  #   default. A content editor could therefore create a knowledge base, rewrite every one of its
  #   attributes (#params_for_permission is `params.permit!`) and destroy it outright
  #   (#destroy is `full_destroy!`), while the neighbouring #activate / #deactivate correctly
  #   refused them. See zammad/coordination-security#153.
  context 'when user is a knowledge base editor without admin.knowledge_base' do
    let(:user) { create(:user, roles: [role]) }
    let(:role) { create(:role, permission_names: ['knowledge_base.editor']) }

    it 'holds the editor permission but not the administrative one', :aggregate_failures do
      expect(user.permissions?('knowledge_base.editor')).to be true
      expect(user.permissions?('admin.knowledge_base')).to be false
    end

    it { is_expected.to forbid_actions(*actions) }
  end

  context 'when user is a knowledge base reader' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(*actions) }
  end

  context 'when user is non-kb-user' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(*actions) }
  end

  describe 'the permission map' do
    let(:user) { create(:admin) }

    # Administering the knowledge base is `admin.knowledge_base` throughout, so the default is the
    #   whole rule here rather than a fallback for whatever was not named.
    it 'requires the administrative permission for anything not named' do
      expect(described_class.action_permissions_map.default).to eq('admin.knowledge_base')
    end

    it 'names no action separately, so nothing can outrank that default' do
      expect(described_class.action_permissions_map).to be_empty
    end
  end
end
