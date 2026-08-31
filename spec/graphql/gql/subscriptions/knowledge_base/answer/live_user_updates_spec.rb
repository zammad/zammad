# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::KnowledgeBase::Answer::LiveUserUpdates, :aggregate_failures, authenticated_as: :editor, performs_jobs: true, type: :graphql do
  let(:knowledge_base) { create(:knowledge_base) }
  let(:category)       { create(:knowledge_base_category, knowledge_base:) }
  let(:answer)         { create(:knowledge_base_answer, :internal, category:) }
  let(:kb_locale)      { 'en-us' }

  # 'ticket.agent' alongside the editor permission, which is what an agent who also writes
  #   documentation holds. It is needed to *see* the other editors rather than to subscribe:
  #   UserPolicy#nested_show? takes ticket or admin permission as the mark of staff, so a role with
  #   knowledge base access alone sees an empty list (pinned below).
  let(:editor_role)      { create(:role, permission_names: %w[ticket.agent knowledge_base.editor]) }
  let(:kb_only_role)     { create(:role, permission_names: 'knowledge_base.editor') }
  let(:reader_role)      { create(:role, permission_names: 'knowledge_base.reader') }

  let(:editor)       { create(:user, roles: [editor_role]) }
  let(:other_editor) { create(:user, roles: [editor_role]) }

  # The subscriber's own tab, which is what #subscribe reads the initial list out of.
  let(:subscriber) { editor }

  let(:mock_channel) { build_mock_channel }
  let(:variables)    { { key: Taskbar.entity_key(answer, kb_locale), app: 'desktop' } }

  let(:subscription) do
    <<~QUERY
      subscription knowledgeBaseAnswerLiveUserUpdates($key: String!, $app: EnumTaskbarApp!) {
        knowledgeBaseAnswerLiveUserUpdates(key: $key, app: $app) {
          liveUsers {
            user {
              firstname
              lastname
            }
            apps {
              name
              editing
            }
          }
        }
      }
    QUERY
  end

  # By design a taskbar may only be written for its own owner, so every tab has to be created as
  #   that user.
  def create_tab_for(user, locale: kb_locale)
    UserInfo.with_user_id(user.id) do
      create(:taskbar, :with_knowledge_base_answer, answer:, kb_locale: locale, user: user, app: 'desktop')
    end
      .tap { perform_enqueued_jobs }
  end

  # [] rather than nil for "a broadcast arrived carrying nobody", so that a *missing* broadcast
  #   cannot pass an assertion about who is in the list.
  def broadcast_live_users
    messages = mock_channel.mock_broadcasted_messages

    raise 'no live user broadcast arrived' if messages.blank?

    messages
      .last
      .dig(:result, 'data', 'knowledgeBaseAnswerLiveUserUpdates', 'liveUsers')
      .pluck('user')
  end

  def name_of(user)
    { 'firstname' => user.firstname, 'lastname' => user.lastname }
  end

  before do
    create_tab_for(subscriber)

    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  it 'subscribes and delivers the own tab' do
    expect(gql.result.data[:liveUsers].size).to eq(1)
    expect(gql.result.data[:liveUsers].first).to include('user' => name_of(editor))
  end

  it 'delivers another editor opening the same translation' do
    create_tab_for(other_editor)

    expect(broadcast_live_users).to include(name_of(other_editor))
  end

  it 'drops an editor closing the tab again' do
    other_tab = create_tab_for(other_editor)

    UserInfo.with_user_id(other_editor.id) { other_tab.destroy! }
    perform_enqueued_jobs

    expect(broadcast_live_users).not_to include(name_of(other_editor))
  end

  # An editors' list is no place for somebody who may not edit - see
  #   Taskbar#target_accessible_to_owner?, which asks KnowledgeBase::AnswerPolicy#update? for this
  #   key. A reader opens no edit tab in the first place; this pins what happens if one exists all
  #   the same, so that a later "open answers as tabs" change cannot turn readers into live users.
  it 'never delivers somebody who may only read the answer' do
    reader = create(:user, roles: [reader_role])

    KnowledgeBase::PermissionsUpdate.new(category).update!(reader_role => 'reader')

    create_tab_for(reader)

    expect(broadcast_live_users).not_to include(name_of(reader))
  end

  # One answer edited in two languages is two tabs and two lists - the locale is the qualifier of
  #   the key (see Taskbar.entity_key), and `related_taskbars` matches on the whole key. Asserted on
  #   the channel rather than on the list, because a different key means no broadcast reaches this
  #   subscriber at all.
  it 'ignores an editor working on another translation' do
    create_tab_for(other_editor, locale: 'de-de')

    expect(mock_channel.mock_broadcasted_messages).to be_empty
  end

  # Documents a limitation rather than a decision. UserPolicy#nested_show? takes ticket or admin
  #   permission as the mark of staff, so a subscriber holding knowledge base access alone may not
  #   look at their fellow editors: their entries are dropped, and only the subscriber's own
  #   (#own_account?) survives - which the frontend filters out anyway, leaving an empty row.
  #
  # Dropping them is what keeps the subscription from failing outright (see the concern). Teaching
  #   the policy that a knowledge base editor is staff too is a change of its own; if it happens,
  #   this example is the one that flips.
  context 'when the subscriber holds knowledge base access alone', authenticated_as: :kb_only_editor do
    let(:kb_only_editor) { create(:user, roles: [kb_only_role]) }
    let(:subscriber)     { kb_only_editor }

    before do
      create_tab_for(other_editor)

      gql.execute(subscription, variables: variables, context: { channel: mock_channel })
    end

    it 'delivers only the subscriber themselves' do
      expect(gql.result.data[:liveUsers].pluck('user')).to eq([name_of(kb_only_editor)])
    end
  end

  # Not 'ticket.agent' like the ticket counterpart, and not open to a reader either.
  context 'when the user may only read the knowledge base', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [reader_role]) }

    it 'refuses the subscription' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
