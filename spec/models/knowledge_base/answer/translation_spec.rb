# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, current_user_id: 1, type: :model do
  subject { create(:knowledge_base_answer_translation) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:answer_id).with_message(%r{}) }

  it { is_expected.to belong_to(:answer) }
  it { is_expected.to belong_to(:kb_locale) }

  def handle_elasticsearch(enabled)
    if enabled
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    else
      Setting.set('es_url', nil)
    end
  end

  describe '.search' do
    include_context 'basic Knowledge Base'

    [true, false].each do |elasticsearch|
      context "when ES=#{elasticsearch}", searchindex: elasticsearch do
        shared_examples 'verify given user' do |trait:, user_id:, is_visible:|
          prefix = is_visible ? 'lists' : 'does not list'

          it "#{prefix} #{trait} answer to #{user_id}" do
            user   = create(user_id)
            object = create(:knowledge_base_answer, trait, knowledge_base: knowledge_base)

            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: object.translations.first.title, current_user: user })).to is_visible ? be_present : be_blank
          end
        end

        shared_examples 'verify given permissions' do |trait:, admin:, agent:, customer:|
          context "when permission is #{trait}" do
            include_examples 'verify given user', trait: trait, user_id: :admin,    is_visible: admin
            include_examples 'verify given user', trait: trait, user_id: :agent,    is_visible: agent
            include_examples 'verify given user', trait: trait, user_id: :customer, is_visible: customer
          end
        end

        describe 'non-granular permissions' do
          include_examples 'verify given permissions', trait: :published, admin: true, agent: true,  customer: false
          include_examples 'verify given permissions', trait: :internal,  admin: true, agent: true,  customer: false
          include_examples 'verify given permissions', trait: :draft,     admin: true, agent: false, customer: false
          include_examples 'verify given permissions', trait: :archived,  admin: true, agent: false, customer: false
        end

        describe 'multiple KBs support' do
          it 'searches in multiple KBs' do
            title = Faker::Appliance.equipment

            create_list(:knowledge_base_answer, 2, :published, translation_attributes: { title: title })

            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: title, current_user: create(:admin) }).count).to be 2
          end
        end

        describe 'granular permissions' do
          let(:user) { create(:agent) }

          it 'returns given answer when granular permissions allow' do
            KnowledgeBase::PermissionsUpdate.new(internal_answer.category).update! user.roles.first => 'reader'
            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: internal_answer.translations.first.title, current_user: user })).to be_present
          end

          it 'does not return given answer when granular permissions forbids' do
            KnowledgeBase::PermissionsUpdate.new(internal_answer.category).update! user.roles.first => 'none'
            handle_elasticsearch(elasticsearch)

            expect(described_class.search({ query: internal_answer.translations.first.title, current_user: user })).to be_blank
          end
        end
      end
    end
  end
end
