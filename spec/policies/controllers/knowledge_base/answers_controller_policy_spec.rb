# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Controllers::KnowledgeBase::AnswersControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::AnswersController }
  let(:record) do
    rec             = record_class.new
    rec.params      = params

    rec
  end

  let(:params) { { id: internal_answer.id, category_id: category.id } }

  # Spelled out rather than derived from CanBePublished::StateMachine, which is what the policy
  #   itself derives its predicates from - the spec has to be an independent statement of which
  #   actions exist, or it would agree with the implementation about a missing one.
  let(:publishing_actions) do
    %i[
      has_publishing_update
      has_publishing_internal
      has_publishing_publish
      has_publishing_archive
      has_publishing_unarchive
    ]
  end

  context 'when user is editor' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
    it { is_expected.to permit_actions(*publishing_actions) }
    it { is_expected.to permit_action(:recent_answers) }
  end

  context 'when user is reader' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(:create, :update, :destroy) }

    # Publishing an answer moves it onto the public help site, and archiving it takes it off
    #   again - editorial writes, so a reader is refused them even though it may read the answer.
    it { is_expected.to forbid_actions(*publishing_actions) }

    # The one action here that is a read for everyone with any knowledge base access:
    #   KnowledgeBase::AnswersController#recent_answers scopes to `published`.
    it { is_expected.to permit_action(:recent_answers) }
  end

  context 'when user is non-kb-user' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
    it { is_expected.to forbid_actions(*publishing_actions) }
    it { is_expected.to forbid_action(:recent_answers) }
  end

  context 'when using granular permissions' do
    let(:user) { create(:user, role_ids: [role.id]) }
    let(:role) { create(:role, permission_names: ['knowledge_base.editor']) }

    before do
      KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => 'reader'
      KnowledgeBase::PermissionsUpdate.new(category).update! role => access
    end

    context 'when parent category is editable' do
      let(:access) { 'editor' }

      it { is_expected.to permit_actions(:show, :create, :update, :destroy) }
      it { is_expected.to permit_actions(*publishing_actions) }
    end

    context 'when parent category is not editable' do
      let(:access) { 'reader' }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_actions(:create, :update, :destroy) }
      it { is_expected.to forbid_actions(*publishing_actions) }
    end

    context 'when parent category is unreachable' do
      let(:access) { 'none' }

      it { is_expected.to forbid_actions(:show, :create, :update, :destroy) }
      it { is_expected.to forbid_actions(*publishing_actions) }
    end
  end

  # The publishing actions are the ones that had no predicate and fell through to a permissive
  #   default, so what matters is that every one the controller answers is gated - not just the
  #   ones this spec happens to name.
  describe 'coverage of the publishing actions' do
    let(:user) { create(:admin) }

    it 'gates every publishing action the controller defines' do
      defined_actions = KnowledgeBase::AnswersController
        .action_methods
        .grep(%r{\Ahas_publishing_})
        .map { |action| :"#{action}" }

      expect(defined_actions).to match_array(publishing_actions)
    end

    it 'answers each of them with a predicate rather than the permission map', :aggregate_failures do
      publishing_actions.each do |action|
        expect(described_class.action_permissions_map).not_to have_key(:"#{action}?")
        expect(described_class).to be_method_defined(:"#{action}?")
      end
    end
  end

  # These actions carry no `category_id` - the answer is already filed. So they must resolve access
  #   through the answer alone, which is why they use #access(:update?) and not this policy's own
  #   #update?, whose #verify_category would look for a param that is never there.
  context 'when the request carries no category_id' do
    let(:params) { { id: internal_answer.id } }

    context 'when user is editor' do
      let(:user) { create(:admin) }

      it { is_expected.to permit_actions(*publishing_actions) }
    end

    context 'when user is reader' do
      let(:user) { create(:agent) }

      it { is_expected.to forbid_actions(*publishing_actions) }
    end
  end
end
