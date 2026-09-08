# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Search', app: :desktop_view, authenticated_as: :authenticate, searchindex: true, type: :system do
  let(:group)                { create(:group) }
  let(:agent)                { create(:agent, groups: [group]) }
  let(:customer)             { create(:customer, :with_org) }
  let(:old_ticket)           { create(:ticket, title: 'Old Ticket Title', group:, customer:, state: Ticket::State.find_by(name: 'closed')) }
  let(:question)             { Faker::Lorem.unique.question }
  let(:old_customer_article) { create(:ticket_article, :inbound_email, ticket: old_ticket, from: customer.email, body: question) }
  let(:answer)               { Faker::Lorem.unique.paragraph(sentence_count: 3) }
  let(:old_agent_article)    { create(:ticket_article, :outbound_email, ticket: old_ticket, from: agent.email, body: answer) }
  let(:new_ticket)           { create(:ticket, title: 'New Ticket Title', group:, customer:) }
  let(:new_customer_article) { create(:ticket_article, :inbound_email, ticket: new_ticket, from: customer.email, body: question) }

  def authenticate
    travel_to 6.months.ago
    UserInfo.current_user_id = customer.id
    old_customer_article
    UserInfo.current_user_id = agent.id
    old_agent_article
    travel_back
    UserInfo.current_user_id = customer.id
    new_customer_article
    searchindex_model_reload([Ticket, Organization, User])
    agent
  end

  before do
    visit "/tickets/#{new_ticket.id}"
  end

  it 'can search for related issues to answer customer ticket' do
    within 'main' do
      expect(page).to have_text(customer.fullname)
        .and have_text(new_customer_article.body)
    end

    within 'aside[aria-label="Main sidebar"]' do
      # The missing closing bracket used to be silently tolerated by Chrome's
      #   lenient CSS parser, but Playwright's selector engine rejects it.
      find('[role="searchbox"][aria-label="Search…"]').fill_in with: customer.fullname

      expect(page).to have_text('Found users')
        .and have_link(customer.fullname)

      click_on 'detailed search'
    end

    # CGI.escapeURIComponent encodes apostrophes as %27, but Vue Router's
    # encodeURI does not. Decode the URL before comparing to handle both.
    wait.until { CGI.unescape(current_url).include?("/search/#{customer.fullname}") }

    within 'main' do
      find('[role="tab"]', text: 'User').click

      expect(page).to have_link(customer.login)

      find('[role="tab"]', text: 'Ticket').click
      find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'foobar'

      expect(page).to have_text('No search results for this query.')

      find('[role="button"][aria-label="Clear search"]').click

      expect(page).to have_text('Start typing or apply filters to get the search results.')

      find('[role="searchbox"][aria-label="Search…"]').fill_in with: "state.name: closed AND article.from: #{agent.fullname} AND customer.firstname: #{customer.firstname}"

      click_on old_ticket.number
    end

    wait.until { current_url.include?("/tickets/#{old_ticket.id}") }

    within 'main' do
      expect(page).to have_text(agent.fullname)
        .and have_text(answer)
    end

    within '#user-taskbar-tabs' do
      click_on 'New Ticket Title'
    end

    within 'main' do
      find('button', text: 'Add internal note').click
      find_editor('Text').type(answer)

      wait_for_form_updater
    end

    within 'footer' do
      click_on 'Update'

      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
    end

    expect(new_ticket.reload.articles.last.body).to include(answer)
  end

  # The quicksearch group for knowledge base answers. `kb_active` needs no setting up - creating an
  #   active knowledge base sets it through KnowledgeBase#set_kb_active_setting - and the agent
  #   holds knowledge_base.reader through the default Agent role, so `canBrowse` is satisfied and
  #   the group's plugin is offered.
  context 'with a knowledge base' do
    include_context 'basic Knowledge Base'

    let(:answer_title) { 'Ocarina tuning guide' }

    let(:kb_answer) do
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: answer_title })
    end

    def authenticate
      kb_answer
      searchindex_model_reload([Ticket, Organization, User, KnowledgeBase::Answer::Translation])
      agent
    end

    it 'finds a knowledge base answer and opens it' do
      within 'aside[aria-label="Main sidebar"]' do
        find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'Ocarina'

        expect(page).to have_text('Found knowledge base answers').and have_link(answer_title)

        click_on answer_title
      end

      wait.until { current_url.include?("/knowledge-base/locale/#{primary_locale.system_locale.locale}/answer/#{kb_answer.id}") }
    end

    # The details popover, loaded only when it opens - so this is also the one check that the new
    #   light query works against the real backend rather than a mock.
    it 'shows the answer details in a popover' do
      within 'aside[aria-label="Main sidebar"]' do
        find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'Ocarina'

        expect(page).to have_link(answer_title)

        find('a', text: answer_title).hover
      end

      within '[role="region"]' do
        expect(page).to have_text(answer_title)
          .and have_text('Language')
          .and have_text('Published')
      end
    end

    it 'omits the group when the knowledge base is deactivated' do
      knowledge_base.update!(active: false)

      refresh

      within 'aside[aria-label="Main sidebar"]' do
        find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'Ocarina'

        expect(page).to have_no_text('Found knowledge base answers')
      end
    end

    # The detailed search tab. Reached by clicking rather
    #   than by visiting the URL, because visiting a /search URL directly does not establish the
    #   taskbar tab.
    it 'lists the answer in its own detailed search tab and opens it' do
      within 'aside[aria-label="Main sidebar"]' do
        find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'Ocarina'

        expect(page).to have_text('Found knowledge base answers')

        click_on 'detailed search'
      end

      within 'main' do
        find('[role="tab"]', text: 'Knowledge base answer').click

        expect(page).to have_css('th', text: 'Name')
          .and have_css('th', text: 'Updated at')
          .and have_css('th', text: 'Visibility')

        click_on answer_title
      end

      wait.until { current_url.include?("/knowledge-base/locale/#{primary_locale.system_locale.locale}/answer/#{kb_answer.id}") }
    end

    context 'with more answers than the group shows' do
      let(:extra_answers) do
        Array.new(11) do |index|
          create(:knowledge_base_answer, :published, category:,
                                                     translation_attributes: { title: "Ocarina note #{index}" })
        end
      end

      def authenticate
        kb_answer
        extra_answers
        searchindex_model_reload([Ticket, Organization, User, KnowledgeBase::Answer::Translation])
        agent
      end

      it 'caps the group and links to the detailed search for the rest' do
        within 'aside[aria-label="Main sidebar"]' do
          find('[role="searchbox"][aria-label="Search…"]').fill_in with: 'Ocarina'

          expect(page).to have_text('Found knowledge base answers')

          click_on '2 more'
        end

        within 'main' do
          expect(page).to have_css('[role="tab"][aria-selected="true"]', text: 'Knowledge base answer')
        end
      end
    end
  end
end
