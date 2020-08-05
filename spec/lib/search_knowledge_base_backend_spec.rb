require 'rails_helper'

RSpec.describe SearchKnowledgeBaseBackend do
  include_context 'basic Knowledge Base'

  context 'with user trait and object state' do
    def expected_visibility_instance(ui_identifier)
      options = {
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        scope:          nil,
        flavor:         ui_identifier
      }

      described_class.new options
    end

    shared_examples 'verify given search backend' do |permissions:, ui:, elasticsearch:|
      is_visible = permissions == :all || permissions == ui
      prefix     = is_visible ? 'lists' : 'does not list'

      it "#{prefix} in #{ui} interface when ES=#{elasticsearch}", searchindex: elasticsearch do
        instance = expected_visibility_instance ui
        object
        configure_elasticsearch(required: true, rebuild: true) if elasticsearch
        expect(instance.search(object.translations.first.title, user: user)).to is_visible ? be_present : be_blank
      end
    end

    shared_examples 'verify given permissions' do |scope:, trait:, admin:, agent:|
      context "with #{trait} #{scope}" do
        let(:object) { create("knowledge_base_#{scope}", trait, knowledge_base: knowledge_base) }

        include_examples 'verify given user', user_id: :admin, permissions: admin
        include_examples 'verify given user', user_id: :agent, permissions: agent
      end
    end

    shared_examples 'verify given user' do |user_id:, permissions:|
      context "with #{user_id}" do
        let(:user) { create(user_id) }

        include_examples 'verify given search backend', permissions: permissions, ui: :agent, elasticsearch: true
        include_examples 'verify given search backend', permissions: permissions, ui: :agent, elasticsearch: false

        include_examples 'verify given search backend', permissions: permissions, ui: :public, elasticsearch: true
        include_examples 'verify given search backend', permissions: permissions, ui: :public, elasticsearch: false
      end
    end

    include_examples 'verify given permissions', scope: :answer, trait: :published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :answer, trait: :internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :answer, trait: :draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :answer, trait: :archived,  admin: :all, agent: :none

    include_examples 'verify given permissions', scope: :category, trait: :empty,                admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :category, trait: :containing_internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :category, trait: :containing_draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_archived,  admin: :all, agent: :none
  end
end
