# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase::Answer, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseAnswer($answerId: ID!, $locale: String) {
        knowledgeBaseAnswer(answerId: $answerId, locale: $locale) {
          id
          title
          content { id bodyWithUrls bodyForEditing }
          visibility
          translationId
          translationMissing
          internalAt
          publishedAt
          archivedAt
          editedAt
          visibilitySchedules {
            visibility
            scheduledAt
          }
          editedBy { id fullname }
          tags
          attachments { id internalId name size type preferences }
          navigation {
            index
            totalCount
            previousAnswer { id title }
            nextAnswer { id title }
          }
          category {
            id
            breadcrumb { id title }
          }
        }
      }
    GQL
  end
  let(:answer)    { published_answer }
  let(:answer_id) { gql.id(answer) }
  let(:locale)    { nil }
  let(:variables) { { answerId: answer_id, locale: }.compact }

  before do
    answer
    gql.execute(query, variables:)
  end

  context 'with an admin (editor)', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'returns the answer' do
      expect(gql.result.data).to include('id' => gql.id(answer))
    end

    it 'resolves the title from the answer translation' do
      expect(gql.result.data).to include('title' => answer.translation_primary.title)
    end

    it 'resolves the body from the answer translation content', :aggregate_failures do
      content = answer.translation_primary.content

      expect(gql.result.data['content']).to include('id' => gql.id(content))
      expect(gql.result.data['content']).to include('bodyWithUrls' => KnowledgeBaseRichText.prepare(content.body_with_urls, &:desktop_url))
    end

    # What a reader gets rendered is not what an editor may load: `bodyWithUrls` expands the video
    #   widget marker into an `<iframe>`, and an editor saving that back would store the rendering in
    #   place of the marker and lose the widget for good. `bodyForEditing` is the stored body, with
    #   only the inline image URLs resolved.
    context 'with a body containing a video widget' do
      let(:answer) { create(:knowledge_base_answer, :with_video, :published, category: category) }

      it 'renders the widget for reading and hands the editor the marker', :aggregate_failures do
        expect(gql.result.data.dig('content', 'bodyWithUrls')).to include('<iframe')
        expect(gql.result.data.dig('content', 'bodyForEditing')).to include('widget: video')
        expect(gql.result.data.dig('content', 'bodyForEditing')).not_to include('<iframe')
      end
    end

    # The editor stores a link to another answer as a marker (`data-target-type`/`data-target-id`
    #   on the anchor); the href it carries is a legacy-stack URL. It has to be resolved to this
    #   app's own answer route, so following it stays inside the app.
    context 'with a body linking to another answer' do
      let(:linked_answer) { published_answer_in_other_category }

      before do
        answer.translation_primary.content.update!(
          body: "<a href='#knowledge_base/1/locale/en-us/answer/9999' data-target-type='knowledge-base-answer' data-target-id='#{linked_answer.translation_primary.id}'>See also</a>"
        )
        gql.execute(query, variables:)
      end

      it 'resolves the link to the desktop answer route', :aggregate_failures do
        expect(gql.result.payload['errors']).to be_nil
        expect(gql.result.data.dig('content', 'bodyWithUrls'))
          .to include(%(href="/desktop/knowledge-base/locale/#{locale_name}/answer/#{linked_answer.id}"))
      end
    end

    context 'with a body linking to an answer that no longer exists' do
      before do
        answer.translation_primary.content.update!(
          body: "<a href='#knowledge_base/1/locale/en-us/answer/9999' data-target-type='knowledge-base-answer' data-target-id='9999'>See also</a>"
        )
        gql.execute(query, variables:)
      end

      it 'resolves the link to a placeholder', :aggregate_failures do
        expect(gql.result.payload['errors']).to be_nil
        expect(gql.result.data.dig('content', 'bodyWithUrls')).to include('href="#"')
      end
    end

    context 'with an answer that has no translation at all' do
      before do
        answer.translations.destroy_all
        gql.execute(query, variables:)
      end

      it 'returns no content instead of erroring', :aggregate_failures do
        expect(gql.result.data).to include('content' => nil)
        expect(gql.result.payload['errors']).to be_nil
      end

      it 'returns no translation ID' do
        expect(gql.result.data).to include('translationId' => nil)
      end
    end

    # Records that hang off a translation rather than the answer — links, for one —
    #   are addressed by this ID.
    it 'exposes the ID of the answer translation' do
      expect(gql.result.data).to include('translationId' => gql.id(answer.translation_primary))
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it 'color-codes the publication state' do
        expect(gql.result.data).to include('visibility' => 'draft')
      end
    end

    context 'with an internal answer' do
      let(:answer) { internal_answer }

      it 'exposes the internal publication date', :aggregate_failures do
        expect(gql.result.data).to include('visibility' => 'internal')
        expect(gql.result.data['internalAt']).to be_present
      end
    end

    context 'with an archived answer' do
      let(:answer) { archived_answer }

      it 'exposes the archival date', :aggregate_failures do
        expect(gql.result.data).to include('visibility' => 'archived')
        expect(gql.result.data['archivedAt']).to be_present
      end
    end

    it 'exposes the publication date of a published answer' do
      expect(gql.result.data['publishedAt']).to be_present
    end

    # The dates still ahead, as opposed to `visibility`, which is the state the answer is in now -
    #   both are derived from the very same columns.
    context 'with an answer scheduled to be archived' do
      let(:answer) { create(:knowledge_base_answer, :published, category:, archived_at: 1.week.from_now.change(sec: 0)) }

      it 'exposes the schedule beside the state it is in', :aggregate_failures do
        expect(gql.result.data).to include('visibility' => 'published')
        expect(gql.result.data['visibilitySchedules'].sole)
          .to eq('visibility' => 'archived', 'scheduledAt' => answer.archived_at.iso8601)
      end

      # Unfiltered for an editor, unlike for everybody else: their views show what is in effect
      #   beside what is scheduled, and both come off this column.
      it 'exposes the raw date as well' do
        expect(gql.result.data['archivedAt']).to eq(answer.archived_at.iso8601)
      end
    end

    context 'with tags assigned to the answer' do
      before do
        answer.tag_add('alpha', admin.id)
        answer.tag_add('beta', admin.id)
        gql.execute(query, variables:)
      end

      it 'exposes the assigned tags' do
        expect(gql.result.data['tags']).to contain_exactly('alpha', 'beta')
      end
    end

    it 'exposes the files attached to the answer' do
      expect(gql.result.data['attachments'].pluck('name')).to eq(%w[hello_world.txt])
    end

    context 'with an answer without attachments' do
      let(:answer) { published_answer_in_other_category }

      it 'exposes an empty list' do
        expect(gql.result.data['attachments']).to be_empty
      end
    end

    context 'with more files attached to the answer' do
      # Added in reverse, so the ordering below is the type's doing and not insertion order.
      before do
        answer.add_attachment(File.open(Rails.root.join('test/data/upload/upload2.jpg')))
        answer.add_attachment(File.open(Rails.root.join('test/data/upload/upload1.txt')))
        gql.execute(query, variables:)
      end

      it 'exposes them sorted by file name', :aggregate_failures do
        expect(gql.result.data['attachments'].pluck('name')).to eq(%w[hello_world.txt upload1.txt upload2.jpg])
        expect(gql.result.data['attachments'].last).to include(
          'internalId' => answer.attachments_sorted.last.id,
          'type'       => 'image/jpeg',
        )
        expect(gql.result.data['attachments'].last['size']).to be_positive
      end

      # The body's inline images live on the translation content, not on the answer, so
      #   they never show up in this list.
      it 'does not include the attachments of the translation content' do
        Store.create!(
          object:      'KnowledgeBase::Answer::Translation::Content',
          o_id:        answer.translation_primary.content.id,
          data:        'x',
          filename:    'inline.png',
          preferences: { 'Content-Type' => 'image/png', 'Content-Disposition' => 'inline' }
        )
        gql.execute(query, variables:)

        expect(gql.result.data['attachments'].pluck('name')).to eq(%w[hello_world.txt upload1.txt upload2.jpg])
      end
    end

    it 'exposes the edit metadata of the answer translation', :aggregate_failures do
      translation = answer.translation_primary

      expect(gql.result.data['editedAt']).to eq(translation.edited_at.iso8601)
      expect(gql.result.data['editedBy']).to include('id' => gql.id(translation.updated_by))
    end

    context 'with an answer in a subcategory' do
      let(:answer) { published_answer_in_subcategory }

      it 'returns the category breadcrumb, root first, including the own category' do
        expect(gql.result.data['category']['breadcrumb'].pluck('id'))
          .to eq([gql.id(category), gql.id(subcategory)])
      end
    end
  end

  context 'with an agent (reader)', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns a published answer' do
      expect(gql.result.data).to include('id' => gql.id(answer))
    end

    # The counterpart to the customer case below: internal access does see the
    #   full editorial lifecycle.
    context 'with an answer that went internal before being published' do
      let(:answer) { create(:knowledge_base_answer, :internal, :published, category: category) }

      it 'exposes the internal date and the editor', :aggregate_failures do
        expect(gql.result.data['internalAt']).to be_present
        expect(gql.result.data['publishedAt']).to be_present
        expect(gql.result.data['editedAt']).to be_present
        expect(gql.result.data['editedBy']).to be_present
      end
    end

    # The one editorial field internal access does *not* buy: acting on a scheduled change takes
    #   editor access, so being told about one does too - and that has to hold for the date it is
    #   derived from as well, or the schedule would just be read off `archivedAt` instead.
    context 'when the answer is scheduled to be archived' do
      let(:answer) { create(:knowledge_base_answer, :internal, :published, category:, archived_at: 1.week.from_now) }

      it 'exposes neither the schedule nor the date it is derived from', :aggregate_failures do
        expect(gql.result.data).to include('visibilitySchedules' => nil)
        expect(gql.result.data['archivedAt']).to be_nil
      end

      # Only the dates still ahead are withheld: how the answer got where it is stays theirs to see.
      it 'exposes the dates the answer has reached', :aggregate_failures do
        expect(gql.result.data['internalAt']).to be_present
        expect(gql.result.data['publishedAt']).to be_present
      end
    end

    context 'with an internal answer' do
      let(:answer) { internal_answer }

      it 'returns the answer' do
        expect(gql.result.data).to include('id' => gql.id(answer))
      end
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with an archived answer' do
      let(:answer) { archived_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with answer navigation' do
    let(:unpublished_answer) { create(:knowledge_base_answer, category: category) }
    let(:next_answer)        { create(:knowledge_base_answer, :published, category: category) }

    before do
      unpublished_answer
      next_answer
      answer.update_column(:position, 1)
      unpublished_answer.update_column(:position, 2)
      next_answer.update_column(:position, 3)
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'includes every visible sibling and returns their localized titles', :aggregate_failures do
        expect(gql.result.data['navigation']).to include('index' => 1, 'totalCount' => 3)
        expect(gql.result.data.dig('navigation', 'previousAnswer')).to include('id' => gql.id(next_answer), 'title' => next_answer.translation_primary.title)
        expect(gql.result.data.dig('navigation', 'nextAnswer')).to include('id' => gql.id(unpublished_answer), 'title' => unpublished_answer.translation_primary.title)
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'only counts and navigates among published siblings', :aggregate_failures do
        expect(gql.result.data['navigation']).to include('index' => 1, 'totalCount' => 2)
        expect(gql.result.data.dig('navigation', 'previousAnswer')).to include('id' => gql.id(next_answer))
        expect(gql.result.data.dig('navigation', 'nextAnswer')).to include('id' => gql.id(next_answer))
      end
    end
  end

  # The path a client actually takes, and the one the service spec cannot cover: the sibling ids
  #   come from AnswerType#navigation_sibling_ids and are passed in as `ids:`, so
  #   Service::KnowledgeBase::AnswerNavigation#sibling_ids is never reached here. Rebuilding that
  #   list by `position` would leave the whole navigation suite above green.
  context 'with answer navigation in a sorting mode', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    let(:zulu)  { answer_titled('Zulu') }
    let(:mike)  { answer_titled('Mike') }
    let(:alpha) { answer_titled('Alpha') }

    let(:answer) { mike }

    def answer_titled(title)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: })
    end

    # Positions handed out against the alphabetical order, so navigating by `position` returns
    #   exactly the opposite neighbours.
    before do
      [zulu, mike, alpha].each.with_index(1) { |sibling, position| sibling.update_column(:position, position) }
      category.update!(answer_sorting_mode: 'alphabetical')
      gql.execute(query, variables:)
    end

    it 'counts and navigates the siblings by title', :aggregate_failures do
      expect(gql.result.data['navigation']).to include('index' => 2, 'totalCount' => 3)
      expect(gql.result.data.dig('navigation', 'previousAnswer')).to include('id' => gql.id(alpha), 'title' => 'Alpha')
      expect(gql.result.data.dig('navigation', 'nextAnswer')).to include('id' => gql.id(zulu), 'title' => 'Zulu')
    end
  end

  # A customer has no knowledge base permission at all, so this covers every user
  #   without one: they reach published content — the public knowledge base — and
  #   nothing else. Mirrors `knowledgeBaseAnswers` and the public help site.
  context 'with a customer (public)', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'has no knowledge base permission' do
      expect(customer.permissions?('knowledge_base.*')).to be(false)
    end

    it 'returns a published answer' do
      expect(gql.result.data).to include('id' => gql.id(answer))
    end

    # The body is the content the public help site renders, so unlike the editorial
    #   metadata it is not withheld from a public reader.
    it 'returns the body of a published answer' do
      expect(gql.result.data.dig('content', 'bodyWithUrls'))
        .to eq(KnowledgeBaseRichText.prepare(answer.translation_primary.content.body_with_urls, &:desktop_url))
    end

    # What the public site shows: that it is published, and when. The editorial
    #   lifecycle around it — when it went internal, when it was archived, who
    #   last edited it and when — stays internal.
    context 'with an answer that went internal before being published' do
      let(:answer) { create(:knowledge_base_answer, :internal, :published, category: category) }

      it 'exposes the publication date' do
        expect(gql.result.data['publishedAt']).to be_present
      end

      it 'exposes no other date and no editor', :aggregate_failures do
        expect(gql.result.data).to include('internalAt' => nil)
        expect(gql.result.data).to include('archivedAt' => nil)
        expect(gql.result.data).to include('editedAt' => nil)
        expect(gql.result.data).to include('editedBy' => nil)
      end

      # Nor what it is going to become: acting on a scheduled change takes editor access, so being
      #   told about one does too - and a schedule is nothing but a date that has not been reached.
      context 'when it is scheduled to be archived' do
        let(:answer) { create(:knowledge_base_answer, :internal, :published, category:, archived_at: 1.week.from_now) }

        it 'exposes no schedule' do
          expect(gql.result.data).to include('visibilitySchedules' => nil)
        end
      end
    end

    context 'with an internal answer' do
      let(:answer) { internal_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with a draft answer' do
      let(:answer) { draft_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with an archived answer' do
      let(:answer) { archived_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

  end

  # A granular denial withdraws *internal* access to a category; it does not
  #   retract content that is published to the public help site anyway. Mirrors
  #   `visible_by_categories`, which scopes readers and public readers separately,
  #   so this query answers exactly what the listing would.
  context 'when granular category permissions deny the answer category' do
    let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:reader)      { create(:user, roles: [reader_role]) }

    before do
      create(:knowledge_base_permission, permissionable: category, role: reader_role, access: 'none')
      gql.execute(query, variables:)
    end

    context 'with a denied reader opening a published answer directly', authenticated_as: :reader do
      it 'returns it, since it is public regardless of the denial' do
        expect(gql.result.data).to include('id' => gql.id(answer))
      end

      # The denial makes them a public reader here, so they get the public view
      #   of it — and never an error, which would make the answer unreadable.
      it 'hides the editorial information without erroring', :aggregate_failures do
        expect(gql.result.data).to include('editedAt' => nil)
        expect(gql.result.data).to include('editedBy' => nil)
        expect(gql.result.payload['errors']).to be_nil
      end
    end

    # The security-relevant half: internal content of a denied category must stay
    #   out of reach, even though AnswerPolicy#show? alone would let a reader in.
    context 'with a denied reader opening an internal answer directly', authenticated_as: :reader do
      let(:answer) { internal_answer }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'without authentication' do
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'when the knowledge base is inactive', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before do
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    # Denied by KnowledgeBase::AnswerPolicy, which gates the read on the knowledge base being
    #   active — the argument is authorized before the resolver gets to look one up.
    it 'is rejected' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  # Mirrors the agent app: non-editors only reach answers translated to the
  #   browsed locale, editors also reach untranslated ones (title falls back).
  context 'when the answer is not translated to the browsed locale' do
    let(:locale) { alternative_locale.system_locale.locale }

    before do
      alternative_locale
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'returns the answer with a fallback title and body', :aggregate_failures do
        expect(gql.result.data).to include('translationMissing' => true)
        expect(gql.result.data['title']).to eq(answer.translation_primary.title)
        expect(gql.result.data.dig('content', 'bodyWithUrls'))
          .to eq(KnowledgeBaseRichText.prepare(answer.translation_primary.content.body_with_urls, &:desktop_url))
      end

      it 'returns the ID of the fallback translation, the one it is showing' do
        expect(gql.result.data).to include('translationId' => gql.id(answer.translation_primary))
      end
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
