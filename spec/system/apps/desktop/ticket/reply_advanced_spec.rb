# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Editor and Advanced Features', app: :desktop_view, authenticated_as: :agent1, type: :system do
  let(:agent1)    { create(:agent, groups: [group]) }
  let(:agent2)    { create(:agent, groups: [group]) }
  let(:signature) { create(:signature) }
  let(:group)     { create(:group, signature:) }
  let(:customer)  { create(:customer) }

  let(:first_cite)  { 'First selectable customer text to cite.' }
  let(:second_cite) { 'Second selectable customer text to cite.' }

  let(:article_body) do
    [
      "<p>#{first_cite}</p>",
      "<p>#{second_cite}</p>",
    ].join
  end

  let(:article) do
    create(:ticket_article, :inbound_email,
           ticket: ticket, body: article_body, content_type: 'text/html', from: customer.email)
  end

  let(:ticket) { create(:ticket, group:, customer:, title: 'Editor scenario test') }

  let(:support_type)    { create(:ticket_time_accounting_type, name: 'Support') }
  let(:consulting_type) { create(:ticket_time_accounting_type, name: 'Consulting') }

  let(:text_module) do
    create(:text_module,
           name:     'greet-customer',
           keywords: 'greet',
           content:  'Hello #{ticket.customer.firstname},') # rubocop:disable Lint/InterpolationCheck
  end

  before do
    skip 'Editor scenario relies on Chrome-specific selection/cursor behavior.' if Capybara.current_driver == :zammad_firefox

    Setting.set('time_accounting', true)
    Setting.set('time_accounting_types', true)
    Setting.set('time_accounting_unit', 'minute')

    # Activating full quote makes the editor add the signature for inline
    # quotes as a side effect, which positions the cursor correctly above the
    # quoted block instead of inside it.
    Setting.set('ui_ticket_zoom_article_email_full_quote', true)

    support_type
    consulting_type
    text_module
    agent2
    article

    visit "/tickets/#{ticket.id}"
    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
  end

  it 'covers the full editor and advanced features scenario', performs_jobs: true do
    cite_article_text(first_cite)

    # The signature is inserted asynchronously after the reply form opens -
    # typing before it landed can swallow the keystrokes.
    wait_for_test_flag('editor.signatureAdd')
    editor = find_editor('Text')
    wait_for_editor_ready(editor)
    editor_focus_flag = editor_test_flag(editor, 'focused')
    wait_for_test_flag(editor_focus_flag)

    editor.input_element.send_keys(' First reply text.')

    cite_article_text(second_cite)
    find_editor('Text').input_element.send_keys(' Second reply text.')

    expect_toolbar_visible_while_scrolling

    insert_text_module_at_top

    apply_heading_to_current_block('Heading 1')

    add_h2_below_top_heading('Customer wrote')

    add_h2_before_second_cite('Customer continued')

    insert_table_at_end_of_draft
    select_table_option('Toggle header row')
    select_table_option('Toggle header column')
    fill_first_table_cell('A1')
    insert_row_between_existing_rows

    add_tag('editor-scenario')

    click_on 'Update'

    account_time(type: 'Support', minutes: '15')

    add_internal_note_with_mention(agent2, editor_focus_flag:)

    perform_enqueued_jobs

    expect_subscriber_avatar(agent2)
  end

  # TipTap on macOS does not bind Cmd+Up / Cmd+Down to "start/end of
  # document", so sending those shortcuts leaves the caret wherever the click
  # landed. Drive ProseMirror's selection directly via the DOM Selection API.
  def move_editor_cursor_to_edge(collapse_to_start)
    page.execute_script(<<~JS)
      var box = document.querySelector('#ticketArticleReplyForm [role="textbox"]');
      if (!box) return;
      box.focus();
      var range = document.createRange();
      range.selectNodeContents(box);
      range.collapse(#{collapse_to_start});
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    JS
  end

  def move_editor_cursor_to_start
    move_editor_cursor_to_edge(true)
  end

  def move_editor_cursor_to_end
    move_editor_cursor_to_edge(false)
  end

  # The editor toolbar is sticky below the ticket header. With a draft long
  # enough to scroll, the toolbar has to stay reachable - fully inside the
  # viewport and below the header - while scrolling up/down in the draft.
  def expect_toolbar_visible_while_scrolling
    editor = find_editor('Text').input_element

    # Make sure the draft includes some lines so it can be scrolled.
    8.times { |i| editor.send_keys(:enter, "Draft filler line #{i + 1}.") }

    scroll_area = %(document.querySelector('[data-test-id="ticket-detail-content-container"]'))

    page.execute_script("#{scroll_area}.scrollTop = #{scroll_area}.scrollHeight")
    expect_editor_toolbar_reachable

    page.execute_script("#{scroll_area}.scrollTop -= 150")
    expect_editor_toolbar_reachable

    page.execute_script("#{scroll_area}.scrollTop = #{scroll_area}.scrollHeight")
    expect_editor_toolbar_reachable
  end

  def expect_editor_toolbar_reachable
    # Retry via wait.until, so transient layout states (e.g. the top bar
    # swapping between full and clipped details on scroll) do not flake.
    wait.until do
      page.evaluate_script(<<~JS)
        (function () {
          var toolbar = document.querySelector('#ticketArticleReplyForm [role="toolbar"]');
          if (!toolbar) return false;
          var rect = toolbar.getBoundingClientRect();
          var headerBottom = 0;
          document.querySelectorAll('[data-test-id="ticket-detail-top-bar-clipped-details"], [data-test-id="ticket-detail-top-bar-full-details"]').forEach(function (header) {
            var headerRect = header.getBoundingClientRect();
            if (headerRect.height > 0) headerBottom = Math.max(headerBottom, headerRect.bottom);
          });
          return rect.height > 0 && rect.top >= headerBottom - 1 && rect.bottom <= window.innerHeight;
        })()
      JS
    end
  end

  def cite_article_text(text)
    expect(page).to have_css("#article-#{article.id} .inner-article-body p", text: text)

    page.execute_script(<<~JS)
      var root = document.querySelector('#article-#{article.id} .inner-article-body');
      var paragraph = Array.from(root.querySelectorAll('p')).find(function (node) {
        return node.textContent === #{text.to_json};
      });
      var range = document.createRange();
      range.selectNodeContents(paragraph);
      var selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    JS

    within "#article-#{article.id}" do
      find('button', exact_text: 'Reply', visible: :all).click
    end

    expect(page).to have_css('blockquote', text: text)
  end

  def reply_form
    find('#ticketArticleReplyForm')
  end

  # Click an editor toolbar action by its accessible label, falling back to the
  # "Overflow menu" popover when the toolbar wraps and the action is not
  # rendered directly. The popover items appear in the body, outside the form.
  def click_editor_toolbar_action(label)
    selector = %(button[aria-label="#{label}"])
    in_toolbar = false
    within(reply_form) do
      if has_css?(selector, wait: 0.5)
        in_toolbar = true
        find(selector).click
      else
        find('button[aria-label="Overflow menu"]').click
      end
    end
    return if in_toolbar

    find('[data-test-id="popover-menu-item"]', exact_text: label).click
  end

  def insert_text_module_at_top
    move_editor_cursor_to_start

    click_editor_toolbar_action('Insert text from text module')

    within '[data-test-id="mention-text"]' do
      find('li[role="option"]', text: text_module.name).click
    end

    within(reply_form) do
      expect(page).to have_text("Hello #{customer.firstname},")
    end
  end

  def apply_heading_to_current_block(level_label)
    click_editor_toolbar_action('Add heading')

    find('[data-test-id="popover-menu-item"]', exact_text: level_label).click

    expected_tag = level_label == 'Heading 1' ? 'h1' : 'h2'
    within(reply_form) do
      expect(page).to have_css(expected_tag)
    end
  end

  # Place cursor at end of the top heading line and press Enter to create a new
  # block between the heading and the first cited blockquote, then format that
  # new block as H2.
  def add_h2_below_top_heading(text)
    move_editor_cursor_to_start
    editor = find_editor('Text').input_element
    editor.send_keys(:end, :enter)

    apply_heading_to_current_block('Heading 2')

    editor.send_keys(text)
  end

  # Position the caret at the end of the "First reply text." paragraph (the
  # block immediately above the second cited blockquote), press Enter to insert
  # a new block between it and the second blockquote, then format as H2.
  def add_h2_before_second_cite(text)
    editor = find_editor('Text').input_element
    first_reply_paragraph = find('#ticketArticleReplyForm [role="textbox"] p', exact_text: 'First reply text.')

    page.execute_script(<<~JS, first_reply_paragraph.native)
      var paragraph = arguments[0];
      var range = document.createRange();
      range.selectNodeContents(paragraph);
      range.collapse(false);
      var selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    JS

    editor.send_keys(:enter)

    apply_heading_to_current_block('Heading 2')

    editor.send_keys(text)
  end

  def insert_table_at_end_of_draft
    move_editor_cursor_to_end

    click_editor_toolbar_action('Insert table')

    within(reply_form) do
      expect(page).to have_table
      # The Insert table action chains an empty <p> at the end of the document
      # which leaves the caret outside the table. Click into the first cell so
      # the contextual "Table options" button becomes available.
      first('table tr:first-child td, table tr:first-child th').click
    end
  end

  def select_table_option(label)
    # The "Table options" button is a separate floating control (absolutely
    # positioned next to the table) rather than a toolbar action.
    find('button[aria-label="Table options"]').click

    find('[data-test-id="popover-menu-item"]', exact_text: label).click
  end

  def fill_first_table_cell(content)
    within(reply_form) do
      cell = first('table tr:first-child td, table tr:first-child th')
      cell.click
      cell.send_keys(content)
    end
  end

  def insert_row_between_existing_rows
    within(reply_form) do
      # Cursor in a cell of the first row → "Insert row below" creates a row
      # between the first and second existing rows.
      first('table tr:first-child td, table tr:first-child th').click
    end

    select_table_option('Insert row below')

    within(reply_form) do
      expect(page).to have_css('table tr', count: 4)
    end
  end

  def add_tag(tag)
    click_on 'Add tag'

    find_autocomplete('Add tag').open.input_element.fill_in(with: tag).send_keys(:tab)

    wait_for_gql('shared/entities/tags/graphql/mutations/assignment/add.graphql', number: 1)

    expect(page).to have_text('Ticket tag added successfully')
    expect(ticket.reload.tag_list).to include(tag)
  end

  def account_time(type:, minutes:)
    expect(page).to have_css('#flyout-ticket-time-accounting', text: 'Time accounting')

    # Wait for the flyout form to fully settle before interacting - its
    # initial form updater response rewrites the activity type select
    # (options), which closes an already-opened dropdown menu.
    wait_for_form_to_settle('form-ticket-time-accounting')

    # find_select must run unscoped because its dropdown menu is teleported to
    # the document body. A `within '#flyout-...'` would scope the menu lookup
    # to the aside and the option click would never find it.
    find_select('Activity type').select_option(type)
    find_input('Accounted time').type(minutes)

    within '#flyout-ticket-time-accounting' do
      click_on 'Account time'
    end

    # Wait for the second ticketUpdate mutation — the first one failed because
    # time accounting was missing, the second one (after the flyout) is the
    # one that actually creates the article. Waiting on this signals that the
    # form's reset/close handler has run.
    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql', number: 2)

    expect(page).to have_text('Ticket updated successfully.')

    last_article = ticket.reload.articles.last
    expect(last_article.ticket_time_accounting).to be_present
    expect(last_article.ticket_time_accounting.time_unit.to_i).to eq(minutes.to_i)
  end

  def add_internal_note_with_mention(agent, editor_focus_flag:)
    # Wait for the previously-sent reply article to settle into the list.
    expect(page).to have_css("#article-#{ticket.reload.articles.last.id}")

    # The action panel button renders only after the reply form has fully
    # torn down (form and panel are mutually-exclusive branches in
    # ArticleReply.vue, gated on newArticlePresent), and the whole block is
    # additionally v-show-gated on the article list loading state. Waiting
    # for the button itself covers all of that; the teardown can outlast the
    # default Capybara wait time.
    expect(page).to have_button('Add internal note', wait: 30)

    click_button_when_centered('Add internal note')
    wait_for_test_flag(editor_focus_flag)

    # Wait for the freshly remounted reply form to be ready before
    # interacting with the editor. The Mention user button is part of the
    # note-mode toolbar, and [role="textbox"] is the TipTap editor's input —
    # both render once the form has finished mounting with the note schema.
    # Use page-level matchers so they re-resolve the form on each retry —
    # the form was just remounted, so a previously-held reply_form element
    # handle from before the submission would be stale.
    expect(page).to have_css('#ticketArticleReplyForm button[aria-label="Mention user"]')
    expect(page).to have_css('#ticketArticleReplyForm [role="textbox"]')

    # Focus the editor and type activator + query in one call, so the
    # mention plugin (200ms debounced) sees a non-empty query at the
    # debounce boundary.
    mention_query = "@@#{agent.firstname}"
    suggestion = '[data-test-id="mention-user"] li[role="option"]'

    editor = find_editor('Text').input_element
    editor.click
    editor.send_keys(mention_query)

    expect(page).to have_css(suggestion, text: agent.fullname)

    find(suggestion, text: agent.fullname).click

    expect(page).to have_css('#ticketArticleReplyForm [data-mention-user-id]', text: agent.fullname)

    click_on 'Update'

    # The internal note submission also opens the Time accounting flyout
    # (because time_accounting is enabled). Skip it.
    within '#flyout-ticket-time-accounting' do
      click_on 'Skip'
    end

    expect(page).to have_text('Ticket updated successfully.')
  end

  def click_button_when_centered(label)
    button = find('button', text: label, exact_text: true)

    page.scroll_to(button, align: :center)
    wait.until { !button.obscured? }

    button.click
  end

  def expect_subscriber_avatar(agent)
    section = find('#ticketSidebar', text: 'Subscribers')
    button = section.first('button')
    section.click if button&.[]('aria-expanded') == 'false'

    within '#ticketSidebar' do
      expect(page).to have_css(%(span[aria-label="Avatar (#{agent.fullname})"]))
    end

    expect(ticket.reload.mentions.map(&:user)).to include(agent)
  end
end
