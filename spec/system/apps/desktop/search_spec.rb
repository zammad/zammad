# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Search', app: :desktop_view, authenticated_as: :authenticate, searchindex: true, type: :playwright do
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

  let(:quick_search) { main_sidebar.get_by_role('searchbox', name: 'Search…') }

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

  # The route of the search encodes the search term, a name may contain an apostrophe.
  def expect_route(route)
    wait_until("Route #{route} not reached") { CGI.unescape(page.url).include?(route) }
  end

  before do
    open_desktop("/tickets/#{new_ticket.id}")
  end

  it 'can search for related issues to answer customer ticket' do
    expect(main_content).to contain_text(customer.fullname)
    expect(main_content).to contain_text(new_customer_article.body)

    quick_search.fill(customer.fullname)

    expect(main_sidebar).to contain_text('Found users')
    expect(main_sidebar.get_by_role('link', name: customer.fullname)).to be_visible

    main_sidebar.get_by_role('link', name: 'detailed search').click
    expect_route("/search/#{customer.fullname}")

    detailed_search = main_content.get_by_role('searchbox', name: 'Search…')

    main_content.get_by_role('tab', name: 'User').click
    expect(main_content.get_by_role('link', name: customer.login)).to be_visible

    main_content.get_by_role('tab', name: 'Ticket').click
    detailed_search.fill('foobar')
    expect(main_content).to contain_text('No search results for this query.')

    main_content.get_by_role('button', name: 'Clear search').click
    expect(main_content).to contain_text('Start typing or apply filters to get the search results.')

    detailed_search.fill("state.name: closed AND article.from: #{agent.fullname} AND customer.firstname: #{customer.firstname}")
    main_content.get_by_role('link', name: old_ticket.number).click
    expect_route("/tickets/#{old_ticket.id}")

    expect(main_content).to contain_text(agent.fullname)
    expect(main_content).to contain_text(answer)

    page.get_by_role('tree', name: 'User taskbar tabs').get_by_role('link', name: 'New Ticket Title').click

    add_internal_note_button.click

    fill_field('Text', answer)

    page.get_by_role('button', name: 'Update', exact: true).click

    wait_until('The note was not added') { new_ticket.reload.articles.last.body.include?(answer) }
  end

  context 'with a knowledge base' do
    include_context 'basic Knowledge Base'

    let(:answer_title) { 'Ocarina tuning guide' }
    let(:answer_route) { "/knowledge-base/locale/#{primary_locale.system_locale.locale}/answer/#{kb_answer.id}" }

    let(:kb_answer) do
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: answer_title })
    end

    def authenticate
      kb_answer
      searchindex_model_reload([Ticket, Organization, User, KnowledgeBase::Answer::Translation])
      agent
    end

    it 'finds a knowledge base answer and opens it' do
      quick_search.fill('Ocarina')

      expect(main_sidebar).to contain_text('Found knowledge base answers')

      main_sidebar.get_by_role('link', name: answer_title).click
      expect_route(answer_route)
    end

    # The details popover, loaded only when it opens - so this is also the one check that the
    #   light query works against the real backend rather than a mock.
    it 'shows the answer details in a popover' do
      quick_search.fill('Ocarina')

      main_sidebar.get_by_role('link', name: answer_title).hover

      details = page.get_by_role('region', name: answer_title)
      expect(details).to contain_text('Language')
      expect(details).to contain_text('Published')
    end

    it 'omits the group when the knowledge base is deactivated' do
      knowledge_base.update!(active: false)

      page.reload
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)

      quick_search.fill('Ocarina')
      wait_for_query('quickSearch')

      expect(main_sidebar).to not_contain_text('Found knowledge base answers')
    end

    # Reached by clicking rather than by visiting the URL, because visiting a /search URL directly
    #   does not establish the taskbar tab.
    it 'lists the answer in its own detailed search tab and opens it' do
      quick_search.fill('Ocarina')

      expect(main_sidebar).to contain_text('Found knowledge base answers')
      main_sidebar.get_by_role('link', name: 'detailed search').click

      main_content.get_by_role('tab', name: 'Knowledge base answer').click

      ['Name', 'Updated at', 'Visibility'].each do |column|
        expect(main_content.get_by_role('columnheader', name: column)).to be_visible
      end

      main_content.get_by_role('link', name: answer_title).click
      expect_route(answer_route)
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
        quick_search.fill('Ocarina')

        expect(main_sidebar).to contain_text('Found knowledge base answers')
        main_sidebar.get_by_role('link', name: '2 more').click

        expect(main_content.get_by_role('tab', name: 'Knowledge base answer')).to have_attribute('aria-selected', 'true')
      end
    end
  end
end
