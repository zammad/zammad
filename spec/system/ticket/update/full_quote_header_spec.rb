require 'rails_helper'

RSpec.describe 'Ticket > Update > Full Quote Header', type: :system, time_zone: 'Europe/London' do
  let(:group) { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }
  let(:ticket_article) { create(:ticket_article, ticket: ticket, from: 'Example Name <asdf1@example.com>') }
  let(:customer) { create(:customer) }

  prepend_before do
    Setting.set 'ui_ticket_zoom_article_email_full_quote_header', full_quote_header_setting
  end

  before do
    UserInfo.current_user_id = customer.id
    visit "ticket/zoom/#{ticket_article.ticket.id}"
  end

  context 'when "ui_ticket_zoom_article_email_full_quote_header" is enabled' do
    let(:full_quote_header_setting) { true }

    it 'includes OP when forwarding' do
      within(:active_content) do
        click_forward

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article)
        end
      end
    end

    it 'includes OP when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).to contain_full_quote(ticket_article)
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
          expect(page).not_to contain_full_quote(ticket_article)
        end
      end
    end

    it 'does not include OP when replying' do
      within(:active_content) do
        highlight_and_click_reply

        within(:richtext) do
          expect(page).not_to contain_full_quote(ticket_article)
        end
      end
    end
  end

  def click_forward
    click '.js-ArticleAction[data-type=emailForward]'
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
      citation.has_text?(name) && citation.has_no_text?(email) && citation.has_text?(timestamp)
    end

    match_when_negated do
      citation.has_no_text?(name) && citation.has_no_text?(email) && citation.has_no_text?(timestamp)
    end

    def citation
      actual.first('blockquote[type=cite]')
    end

    def name
      expected.created_by.fullname
    end

    def email
      expected.created_by.email
    end

    def timestamp
      expected
        .created_at
        .in_time_zone('Europe/London')
        .strftime('%A, %B %1d, %Y, %1I:%M:%S %p')
    end
  end
end
