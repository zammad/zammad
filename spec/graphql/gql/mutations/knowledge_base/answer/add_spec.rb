# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What the answer is made of is Service::KnowledgeBase::Answer::Create's business and is covered
#   there. This is about the mutation around it: its permission gate, the arguments it enforces,
#   the locale it resolves, how the service's refusals reach the client, and what it renders back.
RSpec.describe Gql::Mutations::KnowledgeBase::Answer::Add, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseAnswerAdd($input: KnowledgeBaseCreateAnswerInput!, $locale: String!) {
        knowledgeBaseAnswerAdd(input: $input, locale: $locale) {
          answer {
            id
            title
            content { body }
            category { id }
            visibility
            publishedAt
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:title)       { 'Fresh answer' }
  let(:category_id) { gql.id(category) }
  let(:visibility)  { 'draft' }
  let(:locale)      { primary_locale.system_locale.locale }

  let(:input)     { { categoryId: category_id, title:, tags: [], visibility:, body: '<p>Fresh body</p>' }.compact }
  let(:variables) { { input:, locale: }.compact }

  before do
    # Nothing in the variables refers to the knowledge base, which the service resolves itself — the
    #   shared context creates it lazily, along with the category the answer is filed in.
    category

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the created answer' do
      expect(gql.result.data['answer']).to include(
        'title'    => title,
        'content'  => { 'body' => '<p>Fresh body</p>' },
        'category' => { 'id' => gql.id(category) },
      )
    end

    # The visibility argument has to reach the service as the state it names, and take effect at
    #   once - there is no date to schedule it for later with.
    context 'with a visibility' do
      let(:visibility) { 'published' }

      it 'applies the state right away', :aggregate_failures do
        expect(gql.result.data.dig('answer', 'publishedAt')).to be_present
        expect(gql.result.data.dig('answer', 'visibility')).to eq('published')
      end
    end

    # The payload is rendered in the locale that was written, not in the primary one: its
    #   locale-dependent fields go straight into the client cache.
    context 'with an alternative locale' do
      let(:locale) { alternative_locale.system_locale.locale }

      it 'renders the answer in that locale' do
        expect(gql.result.data.dig('answer', 'title')).to eq(title)
      end
    end

    # Writing the title into another locale than the requested one would leave the client no way to
    #   tell where it ended up.
    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'The selected language does not belong to this knowledge base.'))
      end
    end

    # Refused by the schema, so the presence validation of the translation — whose error could only
    #   be reported on the answer's unrenderable `translations.title` path — is never reached.
    context 'without a title' do
      let(:title) { nil }

      it 'raises an error' do
        expect(gql.result.error_message).to include('invalid value for title (Expected value to not be null)')
      end
    end

    context 'with a blank title' do
      let(:title) { '   ' }

      it 'raises an error' do
        expect(gql.result.error_message).to include('invalid value for title ("   " is not a valid NonEmptyString)')
      end
    end

    context 'without a category' do
      let(:category_id) { nil }

      it 'raises an error' do
        expect(gql.result.error_message).to include('invalid value for categoryId (Expected value to not be null)')
      end
    end

    # And with the field named when the refusal has one, so the form can show it below that field.
    #   No input reaches Exceptions::InvalidAttribute any more (the visibility enum leaves no
    #   unsupported value), so the mapping is exercised through the service directly.
    context 'when the service refuses one of its attributes' do
      let(:setup) do
        allow(Service::KnowledgeBase::Answer::Create)
          .to receive(:new).and_raise(Exceptions::InvalidAttribute.new('visibility', 'Some attribute error.'))
      end

      it 'returns a user error for that field' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'Some attribute error.', 'field' => 'visibility'))
      end
    end

    # A model validation, not a service refusal: KnowledgeBase::HasUniqueTitle reports it on the
    #   answer's `translations.title` path, which is what the form has to map back onto its own
    #   `title` field.
    context 'with a title another answer in the category already has' do
      let(:setup) { create(:knowledge_base_answer, category:, translation_attributes: { title:, kb_locale: primary_locale }) }

      it 'returns a user error naming the translation path' do
        expect(gql.result.data['errors'].first)
          .to include('field' => 'translations.title')
      end
    end
  end

  # Nothing gates the category on the way in, so a granular editor who only reads the knowledge
  #   base itself still gets to the service — which is where the category decides.
  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
    end

    context 'when filing it in the permitted category', authenticated_as: :granular_editor do
      it 'returns the created answer' do
        expect(gql.result.data.dig('answer', 'category')).to eq('id' => gql.id(category))
      end
    end

    context 'when filing it in a category they only read', authenticated_as: :granular_editor do
      let(:category_id) { gql.id(other_category) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
