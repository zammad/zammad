# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > Full Quote Header', current_user_id: -> { current_user.id }, time_zone: 'Europe/London', type: :system do
  let(:group)          { Group.find_by(name: 'Users') }
  let(:ticket)         { create(:ticket, group: group) }
  let(:ticket_article) { create(:ticket_article, ticket: ticket, from: 'Example Name <asdf1@example.com>') }
  let(:customer)       { create(:customer) }
  let(:current_user)   { customer }
  let(:selection)      { '' }

  prepend_before do
    Setting.set 'ui_ticket_zoom_article_email_full_quote_header', full_quote_header_setting
  end

  before do
    visit "ticket/zoom/#{ticket_article.ticket.id}"
  end

  context 'when "ui_ticket_zoom_article_email_full_quote_header" is enabled' do
    let(:full_quote_header_setting) { true }

    it 'includes sender when forwarding' do
      within(:active_content) do
        click_forward

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article).formatted_for(:forward)
        end
      end
    end

    it 'includes sender when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article).formatted_for(:reply)
        end
      end
    end

    it 'includes sender when article visibility toggled' do
      within(:active_content) do
        set_internal
        highlight_and_click_reply

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article).formatted_for(:reply)
        end
      end
    end

    context 'when customer is agent' do
      let(:customer) { create(:agent) }

      it 'includes sender without email when forwarding' do
        within(:active_content) do
          click_forward

          within(:richtext) do
            expect(page).to contain_full_quote(ticket_article).formatted_for(:forward).ensuring_privacy(true)
          end
        end
      end
    end

    # https://github.com/zammad/zammad/issues/3824
    context 'when TO contains multiple senders and one of them is a known Zammad user' do
      let(:customer) { create(:customer) }
      let(:to_1) { "#{customer.fullname} <#{customer.email}>" }
      let(:to_2) { 'Example Two <two@example.org>' }

      let(:ticket_article) { create(:ticket_article, ticket: ticket, to: [to_1, to_2].join(', ')) }

      it 'includes all TO email address' do
        within(:active_content) do
          click_forward

          within(:richtext) do
            expect(page).to have_text(to_1).and(have_text(to_2))
          end
        end
      end
    end

    context 'ticket is created by agent on behalf of customer' do
      let(:agent)          { create(:agent) }
      let(:current_user)   { agent }
      let(:ticket)         { create(:ticket, group: group, title: 'Created by agent on behalf of a customer', customer: customer) }
      let(:ticket_article) { create(:ticket_article, ticket: ticket, from: 'Created by agent on behalf of a customer', origin_by_id: customer.id) }

      it 'includes sender without email when replying' do
        within(:active_content) do
          highlight_and_click_reply

          within(:richtext) do
            expect(page).to contain_full_quote(ticket_article).formatted_for(:reply)
          end
        end
      end
    end

    # https://github.com/zammad/zammad/issues/3855
    context 'when ticket article has no recipient' do
      shared_examples 'when recipient is set to' do |recipient:, recipient_human:|
        context "when recipient is set to #{recipient_human}" do
          let(:ticket_article) { create(:ticket_article, :inbound_web, ticket: ticket, to: recipient) }

          it 'allows to forward without original recipient present' do
            within(:active_content) do
              click_forward

              within(:richtext) do
                expect(page).to contain_full_quote(ticket_article).formatted_for(:forward)
              end
            end
          end
        end
      end

      include_examples 'when recipient is set to', recipient: '', recipient_human: 'empty string'
      include_examples 'when recipient is set to', recipient: nil, recipient_human: 'nil'
    end
  end

  context 'when "ui_ticket_zoom_article_email_full_quote_header" is disabled' do
    let(:full_quote_header_setting) { false }

    it 'does not include sender when forwarding' do
      within(:active_content) do
        click_forward

        within(:richtext) do
          expect(page).not_to contain_full_quote(ticket_article).formatted_for(:forward)
        end
      end
    end

    it 'does not include sender when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).not_to contain_full_quote(ticket_article).formatted_for(:reply)
        end
      end
    end
  end

  context 'when text is selected on page while replying' do
    let(:full_quote_header_setting) { false }
    let(:before_article_content_selector) { '.ticketZoom-header' }
    let(:after_article_content_selector)  { '.ticket-article-item .humanTimeFromNow' }
    let(:article_content_selector)        { '.ticket-article-item .richtext-content' }

    it 'does not quote article when bits other than the article are selected' do
      within(:active_content) do
        highlight_text(before_article_content_selector, '')
        click_reply

        within(:richtext) do
          expect(page).to have_no_text("Test Ticket\nTicket##{ticket.number} - created just now")
        end
      end
    end

    it 'quotes article when bits inside the article are selected' do
      within(:active_content) do
        highlight_text(article_content_selector, '')
        click_reply

        within(:richtext) do
          expect(page).to have_text('some message 123')
        end
      end
    end

    it 'quotes only article when bits before the article are selected as well' do
      within(:active_content) do
        highlight_text(before_article_content_selector, article_content_selector)

        click_reply

        within(:richtext) do
          expect(page).to have_no_text("Test Ticket\nTicket##{ticket.number} - created just now\nsome message 123")
          expect(page).to have_text('some message 123')
        end
      end
    end

    it 'quotes only article when bits after the article are selected as well' do
      within(:active_content) do
        highlight_text(article_content_selector, after_article_content_selector)

        click_reply

        within(:richtext) do
          expect(page).to have_no_text("some message 123\njust now")
          expect(page).to have_text('some message 123')
        end
      end
    end

    it 'quotes only article when bits both before and after the article are selected as well' do
      within(:active_content) do
        highlight_text(before_article_content_selector, after_article_content_selector)

        click_reply

        within(:richtext) do
          expect(page).to have_no_text("Test Ticket\nTicket##{ticket.number} - created just now\nsome message 123\njust now")
          expect(page).to have_text('some message 123')
        end
      end
    end

    context 'when full quote header setting is enabled' do
      let(:full_quote_header_setting) { true }

      it 'can breakout with enter from quote block' do
        within(:active_content) do
          highlight_and_click_reply

          within(:richtext) do
            wait.until do
              first('blockquote br:nth-child(2)', visible: :all)
            end
            blockquote_empty_line = first('blockquote br:nth-child(2)', visible: :all)
            page.driver.browser.action.move_to_location(blockquote_empty_line.native.location.x, blockquote_empty_line.native.location.y).click.perform
          end

          # Special handling for firefox, because the cursor is at the wrong location after the move to with click.
          if Capybara.current_driver == :zammad_firefox
            find(:richtext).send_keys(:down)
          end

          find(:richtext).send_keys(:enter)

          within(:richtext) do
            expect(page).to have_css('blockquote', count: 2)
          end
        end
      end
    end
  end

  def click_forward
    click '.js-ArticleAction[data-type=emailForward]'
  end

  def set_internal
    click '.js-ArticleAction[data-type=internal]'
  end

  def click_reply
    click '.js-ArticleAction[data-type=emailReply]'
  end

  def highlight_text(start_selector, end_selector)
    find(start_selector)
      .execute_script(<<~JAVASCRIPT, end_selector)
        let [ end_selector ] = arguments
        let end_node = $(end_selector)[0]
        if(!end_node) {
          end_node = this.nextSibling
        }
        window.getSelection().removeAllRanges()
        var range = window.document.createRange()
        range.setStart(this, 0)
        range.setEnd(end_node, end_node.childNodes.length)
        window.getSelection().addRange(range)
      JAVASCRIPT
  end

  def highlight_and_click_reply
    find('.ticket-article-item .richtext-content')
      .execute_script <<~JAVASCRIPT
        window.getSelection().removeAllRanges()
        var range = window.document.createRange()
        range.setStart(this, 0)
        range.setEnd(this.nextSibling, 0)
        window.getSelection().addRange(range)
      JAVASCRIPT

    wait.until_constant do
      find('.ticket-article-item .richtext-content').evaluate_script('window.getSelection().toString().trim()')
    end

    click_reply

    within(:richtext) do
      find('blockquote', visible: :all)
    end
  end

  define :contain_full_quote do
    match do
      confirm_content && confirm_style
    end

    match_when_negated do
      confirm_no_content
    end

    # sets expected quote format
    # @param [Symbol] :forward or :reply, defaults to :reply if not set
    chain :formatted_for do |style|
      @style = style
    end

    failure_message do
      if !confirm_style
        string = "expected\n```\n#{citation_text}\n```\nto match "

        case style
        when :reply
          string += '`On...wrote:`'
        when :forward
          string += '`Subject \n Date`'
        end

        return string
      end

      string = "expected\n```\n#{citation_text}\n```\nto "

      case style
      when :reply
        string += "have name `#{name}` and timestamp `#{timestamp_reply}`"

        string += ' but has no name' if citation_text.exclude?(name)
        string += ' but has no timestamp' if !includes_timestamp?(citation_text, timestamp_reply)
      when :forward
        string += "have name `#{name}` and timestamp `#{timestamp_forward}`"

        string += ensure_privacy? ? ' with no email' : " with email `#{email}`"

        string += ' but has no name' if citation_text.exclude?(name)
        string += ' but has no timestamp' if !includes_timestamp?(citation_text, timestamp_forward)
        string += ' but has no email' if !ensure_privacy? && citation_text.include?(email)
      end

      string
    end

    failure_message_when_negated do
      "expected\n```\n#{citation_text}\n```\nto not contain name/email/timestamp"
    end

    def style
      @style || :reply # rubocop:disable RSpec/InstanceVariable
    end

    # sets expected privacy level
    # @param [Boolean] defaults to false if not set
    chain :ensuring_privacy do |flag|
      @ensuring_privacy = flag
    end

    def ensure_privacy?
      @ensuring_privacy || false # rubocop:disable RSpec/InstanceVariable
    end

    def confirm_content
      case style
      when :reply
        confirm_content_reply
      when :forward
        confirm_content_forward
      end
    end

    def confirm_content_reply
      citation_text.include?(name) &&
        citation_text.exclude?(email) &&
        includes_timestamp?(citation_text, timestamp_reply)
    end

    def confirm_content_forward
      citation_text.include?(name) &&
        includes_timestamp?(citation_text, timestamp_forward) &&
        (ensure_privacy? ? citation_text.exclude?(email) : citation_text.include?(email))
    end

    def confirm_no_content
      citation_text.exclude?(name) &&
        citation_text.exclude?(email) &&
        citation_text.exclude?(timestamp_reply) &&
        citation_text.exclude?(timestamp_forward)
    end

    def confirm_style
      case style
      when :forward
        citation_text.match?(%r{Subject(.+)\nDate(.+)})
      when :reply
        citation_text.match?(%r{^On(.+)wrote:$})
      end
    end

    def citation
      actual.first('blockquote[type=cite]')
    end

    delegate :text, to: :citation, prefix: true

    def name
      (expected.origin_by || expected.created_by).fullname
    end

    def email
      expected.created_by.email
    end

    def timestamp_reply
      expected
        .created_at
        .in_time_zone('Europe/London')
        .strftime('%A, %B %1d, %Y at %1I:%M:%S %p')
    end

    def timestamp_forward
      expected
        .created_at
        .in_time_zone('Europe/London')
        .strftime('%m/%d/%Y %1I:%M %P')
    end

    # Chrome started to use non-breaking-space before AM/PM
    # While Firefox still has regular space
    # Using regexp with :space: to match either
    def includes_timestamp?(string, timestamp)
      regexp = Regexp.new timestamp.gsub(' ', '[[:space:]]{1}')

      string.match? regexp
    end
  end
end
