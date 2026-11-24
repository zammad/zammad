# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Editor and Advanced Features', app: :desktop_view, authenticated_as: :agent1, type: :playwright do
  let(:agent1)    { create(:agent, groups: [group]) }
  let(:agent2)    { create(:agent, groups: [group]) }
  let(:signature) { create(:signature) }
  let(:group)     { create(:group, signature:) }
  let(:customer)  { create(:customer) }

  let(:first_cite)  { 'First selectable customer text to cite.' }
  let(:second_cite) { 'Second selectable customer text to cite.' }

  let(:article) do
    create(:ticket_article, :inbound_email,
           ticket: ticket, body: "<p>#{first_cite}</p><p>#{second_cite}</p>", content_type: 'text/html', from: customer.email)
  end

  let(:ticket) { create(:ticket, group:, customer:, title: 'Editor scenario test') }

  let(:text_module) do
    create(:text_module,
           name:     'greet-customer',
           keywords: 'greet',
           content:  'Hello #{ticket.customer.firstname},') # rubocop:disable Lint/InterpolationCheck
  end

  let(:toolbar) { field('Text').get_by_role('toolbar') }
  let(:table)   { editor('Text').get_by_role('table') }

  before do
    Setting.set('time_accounting', true)
    Setting.set('time_accounting_types', true)
    Setting.set('time_accounting_unit', 'minute')

    create(:ticket_time_accounting_type, name: 'Support')
    create(:ticket_time_accounting_type, name: 'Consulting')
    text_module
    agent2
    article

    open_desktop_ticket(ticket)
  end

  def reply
    ticket_article(first_cite).get_by_role('button', name: 'Reply', exact: true).click
  end

  # A triple click selects the paragraph, the reply quotes the selection.
  def reply_with_quote(text)
    ticket_article(first_cite).get_by_text(text, exact: true).click(clickCount: 3)
    reply

    expect(editor('Text').get_by_role('blockquote').filter(hasText: text)).to be_visible
  end

  # The signature is added after the reply form opens and moves the cursor, typing before may get lost.
  def start_reply_with_quote
    reply_with_quote(first_cite)
    wait_for_test_flag('editor.signatureAdd')

    expect(editor('Text')).to be_focused
    type_in_editor('Text', ' First reply text.')
  end

  # ProseMirror learns of a cursor moved by keys only asynchronously, and not at all once a toolbar
  #   button took the focus. A click right of the text puts the cursor at its end right away.
  def click_end_of(block)
    box = block.bounding_box
    block.click(position: { x: box['width'] - 1, y: box['height'] / 2 })
  end

  # A toolbar button takes the focus, and the editor gets it back one animation frame later.
  def expect_editor_focused
    expect(editor('Text')).to be_focused
  end

  def add_heading(level)
    toolbar.get_by_role('button', name: 'Add heading', exact: true).click
    page.get_by_role('region', name: 'Add heading').get_by_role('button', name: level, exact: true).click

    expect_editor_focused
  end

  def insert_text_module
    toolbar.get_by_role('button', name: 'Insert text from text module', exact: true).click
    page.get_by_role('listbox', name: 'Text modules').get_by_role('option', name: text_module.name).click

    expect(editor('Text')).to contain_text("Hello #{customer.firstname},")
  end

  def insert_table
    toolbar.get_by_role('button', name: 'Insert table', exact: true).click

    expect(table).to be_visible
  end

  def choose_table_option(option)
    page.get_by_role('button', name: 'Table options', exact: true).click
    page.get_by_role('menuitem', name: option).click
  end

  # The toolbar sticks below the ticket header, it has to stay in view and uncovered while the
  #   draft scrolls.
  def expect_toolbar_reachable
    page.wait_for_function(<<~JS, arg: toolbar.element_handle)
      (toolbar) => {
        const { top, bottom, left, width } = toolbar.getBoundingClientRect()
        const reachable = (y) => toolbar.contains(document.elementFromPoint(left + width / 2, y))

        return top >= 0 && bottom <= window.innerHeight && reachable(top + 1) && reachable(bottom - 1)
      }
    JS
  rescue Playwright::TimeoutError
    raise 'The editor toolbar is out of view or covered'
  end

  # Both blocks are measured in the same frame, a layout that moves in between would add to the gap.
  def gap_between(first, second)
    page.evaluate(
      '([first, second]) => second.getBoundingClientRect().top - first.getBoundingClientRect().bottom',
      arg: [first.element_handle, second.element_handle],
    )
  end

  def line_height_of(block)
    block.evaluate('(block) => block.getBoundingClientRect().height')
  end

  context 'with an empty line in the article' do
    let(:closing_line) { 'Closing line after an empty one.' }

    let(:article) do
      create(:ticket_article, :inbound_email,
             ticket: ticket, body: "<p>#{first_cite}</p><p>#{second_cite}</p><p></p><p>#{closing_line}</p>", content_type: 'text/html', from: customer.email)
    end

    it 'shows consecutive lines directly beneath each other, and an empty line as one line' do
      first_line  = ticket_article(first_cite).get_by_text(first_cite, exact: true)
      second_line = ticket_article(first_cite).get_by_text(second_cite, exact: true)
      last_line   = ticket_article(first_cite).get_by_text(closing_line, exact: true)

      expect(gap_between(first_line, second_line)).to be_within(0.5).of(0)
      expect(gap_between(second_line, last_line)).to be_within(0.5).of(line_height_of(second_line))
    end
  end

  it 'shows lines typed in the editor directly beneath each other, and an empty line as one line' do
    reply
    wait_for_test_flag('editor.signatureAdd')
    expect_editor_focused
    type_in_editor('Text', 'First line.', :enter, 'Second line.', :enter, :enter, 'Third line.')

    first_line  = editor('Text').get_by_text('First line.', exact: true)
    second_line = editor('Text').get_by_text('Second line.', exact: true)
    third_line  = editor('Text').get_by_text('Third line.', exact: true)

    expect(gap_between(first_line, second_line)).to be_within(0.5).of(0)
    expect(gap_between(second_line, third_line)).to be_within(0.5).of(line_height_of(second_line))
  end

  it 'keeps the editor toolbar reachable while scrolling the draft' do
    start_reply_with_quote

    type_in_editor('Text', *(1..8).flat_map { |line| [:enter, "Draft filler line #{line}."] })

    editor('Text').hover

    scroll_with_wheel(editor('Text'), 5000)
    expect_toolbar_reachable

    scroll_with_wheel(editor('Text'), -150)
    expect_toolbar_reachable

    scroll_with_wheel(editor('Text'), 5000)
    expect_toolbar_reachable
  end

  it 'formats a quoted reply with a text module, headings and a table' do
    start_reply_with_quote

    reply_with_quote(second_cite)
    expect_editor_focused
    type_in_editor('Text', ' Second reply text.')

    # The second quote went to the top, above an empty paragraph.
    editor('Text').get_by_role('paragraph').first.click
    insert_text_module
    add_heading('Heading 1')

    click_end_of(editor('Text').get_by_role('heading', level: 1))
    type_in_editor('Text', :enter)
    add_heading('Heading 2')
    type_in_editor('Text', 'Customer wrote')

    click_end_of(editor('Text').get_by_role('paragraph').filter(hasText: 'First reply text.'))
    type_in_editor('Text', :enter)
    add_heading('Heading 2')
    type_in_editor('Text', 'Customer continued')

    click_end_of(editor('Text').get_by_role('paragraph').filter(hasText: 'Second reply text.'))
    insert_table

    # Inserting the table leaves the cursor in a new paragraph below it.
    table.get_by_role('row').first.click
    choose_table_option('Toggle header row')
    choose_table_option('Toggle header column')

    table.get_by_role('row').first.get_by_role('rowheader').click
    type_in_editor('Text', 'A1')
    choose_table_option('Insert row below')

    expect(editor('Text').get_by_role('heading', level: 1)).to have_text("Hello #{customer.firstname},")
    expect(editor('Text').get_by_role('heading', level: 2)).to have_text(['Customer wrote', 'Customer continued'])
    expect(table.get_by_role('row')).to have_count(4)
    expect(table.get_by_role('row').first.get_by_role('rowheader')).to have_text('A1')
    expect(table.get_by_role('columnheader')).to have_count(0)
  end

  it 'submits a reply with tag and accounted time, then mentions an agent in an internal note', performs_jobs: true do
    start_reply_with_quote

    content_sidebar.get_by_role('button', name: 'Add tag', exact: true).click
    search_for_option('Add tag', 'editor-scenario') { page.keyboard.press('Enter') }

    expect(notification('Tag added successfully')).to be_visible
    expect(ticket.reload.tag_list).to include('editor-scenario')

    page.get_by_role('button', name: 'Update', exact: true).click

    time_accounting = flyout('Time accounting')
    wait_for_form_to_settle('form-ticket-time-accounting')
    select_option('Activity type', 'Support', within: time_accounting)
    fill_field('Accounted time', '15', within: time_accounting)
    time_accounting.get_by_role('button', name: 'Account time', exact: true).click

    wait_until('Reply not created') { ticket.articles.reload.count == 2 }
    expect(ticket.articles.last.ticket_time_accounting).to have_attributes(time_unit: 15)

    add_internal_note_button.click
    mention_in_editor('Text', agent2)
    page.get_by_role('button', name: 'Update', exact: true).click

    wait_for_form_to_settle('form-ticket-time-accounting')
    flyout('Time accounting').get_by_role('button', name: 'Skip', exact: true).click

    wait_until('Internal note not created') { ticket.articles.reload.count == 3 }
    perform_enqueued_jobs

    expect(ticket.reload.mentions.map(&:user)).to include(agent2)
    expect(content_sidebar.get_by_role('group', name: 'Subscribers').get_by_role('img', name: "Avatar (#{agent2.fullname})")).to be_visible
  end

  # An inline quote gets the signature below it, a full quote above it (zammad#2319).
  it 'adds the signature after an inline quote' do
    reply_with_quote(first_cite)
    wait_for_test_flag('editor.signatureAdd')

    expect(editor('Text')).to have_text(%r{#{Regexp.escape(first_cite)}.*#{Regexp.escape(agent1.fullname)}})
  end

  # Without full quote, a reply without a selection opens with an empty body, so the signature
  #   handling is the only thing that fills the editor.
  it 'adds the signature when replying without a selection and without full quote' do
    reply
    wait_for_test_flag('editor.signatureAdd')

    expect(editor('Text')).to contain_text(agent1.fullname)
    expect(editor('Text').get_by_role('blockquote')).to have_count(0)

    expect_editor_focused
    type_in_editor('Text', 'Reply above the signature.')

    expect(editor('Text').get_by_role('paragraph').first).to have_text('Reply above the signature.')
  end
end
