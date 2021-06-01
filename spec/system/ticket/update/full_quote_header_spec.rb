# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > Full Quote Header', current_user_id: -> { current_user.id }, type: :system, time_zone: 'Europe/London' do
  let(:group) { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }
  let(:ticket_article) { create(:ticket_article, ticket: ticket, from: 'Example Name <asdf1@example.com>') }
  let(:customer) { create(:customer) }
  let(:current_user) { customer }

  prepend_before do
    Setting.set 'ui_ticket_zoom_article_email_full_quote_header', full_quote_header_setting
  end

  before do
    visit "ticket/zoom/#{ticket_article.ticket.id}"
  end

  context 'when "ui_ticket_zoom_article_email_full_quote_header" is enabled' do
    let(:full_quote_header_setting) { true }

    it 'includes OP when forwarding' do
      within(:active_content) do
        click_forward

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article).formatted_for(:forward)
        end
      end
    end

    it 'includes OP when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article).formatted_for(:reply)
        end
      end
    end

    it 'includes OP when article visibility toggled' do
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

      it 'includes OP without email when forwarding' do
        within(:active_content) do
          click_forward

          within(:richtext) do
            expect(page).to contain_full_quote(ticket_article).formatted_for(:forward).ensuring_privacy(true)
          end
        end
      end
    end

    context 'ticket is created by agent on behalf of customer' do
      let(:agent)          { create(:agent) }
      let(:current_user)   { agent }
      let(:ticket)         { create(:ticket, group: group, title: 'Created by agent on behalf of a customer', customer: customer) }
      let(:ticket_article) { create(:ticket_article, ticket: ticket, from: 'Created by agent on behalf of a customer', origin_by_id: customer.id) }

      it 'includes OP without email when replying' do
        within(:active_content) do
          highlight_and_click_reply

          within(:richtext) do
            expect(page).to contain_full_quote(ticket_article).formatted_for(:reply)
          end
        end
      end
    end
  end

  context 'when "ui_ticket_zoom_article_email_full_quote_header" is disabled' do
    let(:full_quote_header_setting) { false }

    it 'does not include OP when forwarding' do
      within(:active_content) do
        click_forward

        within(:richtext) do
          expect(page).not_to contain_full_quote(ticket_article).formatted_for(:forward)
        end
      end
    end

    it 'does not include OP when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).not_to contain_full_quote(ticket_article).formatted_for(:reply)
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

  def highlight_and_click_reply
    find('.ticket-article-item .textBubble')
      .execute_script <<~JAVASCRIPT
        window.getSelection().removeAllRanges()
        var range = window.document.createRange()
        range.setStart(this, 0)
        range.setEnd(this.nextSibling, 0)
        window.getSelection().addRange(range)
      JAVASCRIPT

    click '.js-ArticleAction[data-type=emailReply]'
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
      citation.has_text?(name) && citation.has_no_text?(email) && citation.has_text?(timestamp_reply)
    end

    def confirm_content_forward
      if ensure_privacy?
        citation.has_text?(name) && citation.has_no_text?(email) && citation.has_text?(timestamp_forward)
      else
        citation.has_text?(name) && citation.has_text?(email) && citation.has_text?(timestamp_forward)
      end
    end

    def confirm_no_content
      citation.has_no_text?(name) && citation.has_no_text?(email) && citation.has_no_text?(timestamp_reply) && citation.has_no_text?(timestamp_forward)
    end

    def confirm_style
      case style
      when :forward
        citation.text.match?(%r{Subject(.+)\nDate(.+)})
      when :reply
        citation.text.match?(%r{^On(.+)wrote:$})
      end
    end

    def citation
      actual.first('blockquote[type=cite]')
    end

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
        .strftime('%A, %B %1d, %Y, %1I:%M:%S %p')
    end

    def timestamp_forward
      expected
        .created_at
        .in_time_zone('Europe/London')
        .strftime('%m/%d/%Y %H:%M')
    end
  end
end
