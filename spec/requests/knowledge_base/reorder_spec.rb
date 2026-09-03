# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The endpoints behind the legacy interface's "Change order" modal: they store the mode one list is
#   listed in, and - while that mode is `manual` - the hand-made order of the records in it.
#
# The contract is Service::KnowledgeBase::Reorder::Base's, which serves the same two scopes for the
#   desktop view, down to the two refusal messages. It differs in requiring the mode rather than
#   defaulting to the stored one: this modal always has a mode selected, and a request that omitted
#   it would be storing an order under whatever mode happened to be there. See the note on that
#   service for the rest.
RSpec.describe 'KnowledgeBase categories reorder', authenticated_as: :current_user, type: :request do
  include_context 'basic Knowledge Base'

  let(:current_user) { create(:admin) }

  def reorder(url, params)
    patch url, params: params, as: :json
  end

  shared_examples 'ordering one list' do
    it 'stores the submitted order', :aggregate_failures do
      reorder url, { sorting_mode: 'manual', ordered_ids: }

      expect(response).to have_http_status(:ok)
      expect(reordered_ids).to eq(ordered_ids)
    end

    it 'stores the submitted mode' do
      expect { reorder url, { sorting_mode: 'alphabetical' } }
        .to change { node.reload[sorting_mode_attribute] }.from('manual').to('alphabetical')
    end

    # Every submit carries a mode, including the one that only moved a row, so a mode that did not
    #   change must not be rewritten - it would ping every open browse view for nothing. Submitted
    #   with the order the list already has, so the positions do not move either.
    it 'touches nothing when neither the mode nor the order changed' do
      expect { reorder url, { sorting_mode: 'manual', ordered_ids: reordered_ids } }
        .not_to change { node.reload.updated_at }
    end

    # An automatic mode derives the order from the content itself, so there is nothing to number:
    #   the stored positions are left exactly where they were rather than being overwritten with an
    #   order that mode never read.
    it 'leaves the stored positions alone while picking an automatic mode' do
      expect { reorder url, { sorting_mode: 'last_update' } }
        .not_to change { reordered_ids }
    end

    # Without the node the interface would keep rendering the mode it had before the save.
    it 'answers with the node the mode was written to' do
      reorder url, { sorting_mode: 'alphabetical' }

      expect(json_response.dig(node.class.name.gsub('::', ''), node.id.to_s, sorting_mode_attribute.to_s))
        .to eq('alphabetical')
    end

    it 'refuses a request without a mode', :aggregate_failures do
      reorder url, { ordered_ids: }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('sorting_mode')
    end

    it 'refuses an unknown mode' do
      reorder url, { sorting_mode: 'by_phase_of_the_moon' }

      expect(response).to have_http_status(:unprocessable_content)
    end

    # `manual` is the only mode that reads a stored order back, so picking it means saying what the
    #   order is.
    it 'refuses the manual mode without an order', :aggregate_failures do
      reorder url, { sorting_mode: 'manual' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('all items in scope')
    end

    it 'refuses an order against an automatic mode', :aggregate_failures do
      reorder url, { sorting_mode: 'alphabetical', ordered_ids: }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('sorting mode is manual')
    end

    # The whole scope is required: a position is an index into one list, so a partial set cannot say
    #   where the records it leaves out belong.
    it 'refuses a partial order', :aggregate_failures do
      reorder url, { sorting_mode: 'manual', ordered_ids: ordered_ids.first(1) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include('all items in scope')
    end

    # The mode and the order are one write. Its counterpart on the other stack is in
    #   spec/services/service/knowledge_base/reorder/categories_spec.rb.
    it 'stores neither the mode nor the order when the order is refused', :aggregate_failures do
      node.update! sorting_mode_attribute => 'alphabetical'

      expect { reorder url, { sorting_mode: 'manual', ordered_ids: ordered_ids.first(1) } }
        .to not_change { node.reload[sorting_mode_attribute] }
        .and not_change { reordered_ids }
    end

    context 'when the user only reads the parent of that list' do
      let(:current_user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'refuses to order it' do
        reorder url, { sorting_mode: 'alphabetical' }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'the categories of the top level' do
    let(:url)                    { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/reorder_root_categories" }
    let(:ordered_ids)            { knowledge_base.categories.root.reorder(:id).pluck(:id).reverse }
    let(:node)                   { knowledge_base }
    let(:sorting_mode_attribute) { :category_sorting_mode }

    def reordered_ids
      knowledge_base.categories.root.reorder(position: :asc).pluck(:id)
    end

    before { category && other_category }

    include_examples 'ordering one list'
  end

  describe 'the subcategories of a category' do
    let(:url)                    { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_categories" }
    let(:ordered_ids)            { category.children.reorder(:id).pluck(:id).reverse }
    let(:node)                   { category }
    let(:sorting_mode_attribute) { :category_sorting_mode }

    def reordered_ids
      category.children.reorder(position: :asc).pluck(:id)
    end

    before { subcategory && create(:knowledge_base_category, knowledge_base:, parent: category) }

    include_examples 'ordering one list'
  end

  describe 'the answers of a category' do
    let(:url)                    { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_answers" }
    let(:ordered_ids)            { category.answers.reorder(:id).pluck(:id).reverse }
    let(:node)                   { category }
    let(:sorting_mode_attribute) { :answer_sorting_mode }

    def reordered_ids
      category.answers.reorder(position: :asc).pluck(:id)
    end

    before { published_answer && draft_answer }

    include_examples 'ordering one list'

    # The two lists of a category have a mode each, and neither has any say over the other's.
    it 'leaves the mode of its subcategories alone' do
      subcategory

      expect { reorder url, { sorting_mode: 'alphabetical' } }
        .not_to change { category.reload.category_sorting_mode }
    end
  end

  # A category with nothing filed in it can still be given a mode, and the "Change order" button
  #   offers exactly that. It is also the only case where the node in the response assets is
  #   load-bearing: with records in the list the node rides along with theirs
  #   (KnowledgeBase::Category#assets reaches up to its parent), so an empty list is where the
  #   interface would silently stop seeing the mode it just saved.
  describe 'a list with nothing in it' do
    let(:url) { "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_answers" }

    before { category }

    it 'stores an automatic mode and answers with the node', :aggregate_failures do
      reorder url, { sorting_mode: 'alphabetical' }

      expect(response).to have_http_status(:ok)
      expect(category.reload.answer_sorting_mode).to eq('alphabetical')
      expect(json_response.dig('KnowledgeBaseCategory', category.id.to_s, 'answer_sorting_mode')).to eq('alphabetical')
    end

    # An empty list has exactly one order, and the modal sends it as the empty array its empty table
    #   yields. It has to survive as one rather than arrive as a missing parameter, which is what
    #   the manual mode is refused for.
    it 'stores the manual mode with an empty order', :aggregate_failures do
      category.update!(answer_sorting_mode: 'alphabetical')

      reorder url, { sorting_mode: 'manual', ordered_ids: [] }

      expect(response).to have_http_status(:ok)
      expect(category.reload.answer_sorting_mode).to eq('manual')
    end
  end

  # Granular permissions make "editor" a question about one node rather than about the knowledge
  #   base, and ordering a list writes a column of the node the list belongs to - so it is the
  #   parent that has to be editable, not the records being ordered.
  describe 'when the user edits one category only' do
    let(:role)         { create(:role, permission_names: 'knowledge_base.editor') }
    let(:current_user) { create(:user, roles: [role]) }

    before do
      KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role => 'reader'
      KnowledgeBase::PermissionsUpdate.new(category).update! role => 'editor'

      subcategory
      published_answer
    end

    it 'orders the lists of that category', :aggregate_failures do
      reorder "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_categories", { sorting_mode: 'alphabetical' }
      expect(response).to have_http_status(:ok)

      reorder "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{category.id}/reorder_answers", { sorting_mode: 'alphabetical' }
      expect(response).to have_http_status(:ok)
    end

    it 'refuses the list of a category it only reads' do
      reorder "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/#{other_category.id}/reorder_categories", { sorting_mode: 'alphabetical' }

      expect(response).to have_http_status(:forbidden)
    end

    # Being an editor of a category says nothing about the level that category is listed on.
    it 'refuses the top level' do
      reorder "/api/v1/knowledge_bases/#{knowledge_base.id}/categories/reorder_root_categories", { sorting_mode: 'alphabetical' }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
