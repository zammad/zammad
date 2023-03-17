# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Zoom > Email Reply Body', authenticated_as: :authenticate, time_zone: 'Europe/London', type: :system do
  let(:agent)    { create(:agent, groups: [Group.first]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, customer: customer, group: Group.first) }

  def authenticate
    Setting.set 'ui_ticket_zoom_article_email_full_quote', full_quote_setting_enabled
    Setting.set 'ui_ticket_zoom_article_email_full_quote_header', full_quote_header_setting_enabled

    agent
  end

  # Create a ticket article with a specific timestamp and customer origin.
  #   This will allow us to later compare citation header with expected format.
  before do
    timestamp = DateTime.parse('2022-10-06 12:40:00 UTC')
    create(:ticket_article, :inbound_email, ticket: ticket, origin_by: customer, created_at: timestamp)
  end

  context 'when replying to a message' do
    before do
      visit ticket_zoom_path
    end

    context 'without full quote' do
      let(:full_quote_setting_enabled)        { false }
      let(:full_quote_header_setting_enabled) { false }

      it 'body keeps existing content' do
        fill_in_body 'keep me'
        click_reply
        find_reset
        expect(body).to have_text 'keep me'

        # repeat
        fill_in_body 'and me! '
        click_reply
        find_reset
        expect(body).to have_text('keep me').and have_text('and me!')
      end
    end

    context 'with full quote' do
      let(:full_quote_setting_enabled) { true }

      context 'with header' do
        let(:full_quote_header_setting_enabled) { true }

        it 'body contains citation header' do
          click_reply
          expect(body).to contain_citation_header("On Thursday, October 6, 2022 at 1:40:00 PM, #{customer.fullname} wrote:")
        end
      end

      context 'without header' do
        let(:full_quote_header_setting_enabled) { false }

        it 'body does not contain citation header' do
          click_reply
          expect(body).not_to contain_citation_header("On Thursday, October 6, 2022 at 1:40:00 PM, #{customer.fullname} wrote:")
        end
      end

      # Regression test for issue #2344 - Missing translation for Full-Quote-Text "on xy wrote"
      context 'with header in German locale' do
        let(:agent)                             { create(:agent, preferences: { locale: 'de-de' }, groups: [Group.first]) }
        let(:full_quote_header_setting_enabled) { true }

        it 'body contains localized citation header' do
          click_reply
          expect(body).to contain_citation_header("Am Donnerstag, 6. Oktober 2022 um 13:40:00, schrieb #{customer.fullname}:")
        end
      end
    end
  end

  def ticket_zoom_path
    "#ticket/zoom/#{ticket.id}"
  end

  def body
    find(:richtext)
  end

  def fill_in_body(text)
    body.send_keys text
  end

  def find_reset
    find('.js-reset')
  end

  def click_reply
    click '.js-ArticleAction[data-type=emailReply]'
  end

  define :contain_citation_header do
    match do
      contain_citation_header
    end

    match_when_negated do
      contain_no_citation_header
    end

    failure_message do
      return <<~MESSAGE
        expected that citation:

        #{citation_block}

        would contain header:

        #{expected_block}
      MESSAGE
    end

    failure_message_when_negated do
      return <<~MESSAGE
        expected that citation:

        #{citation_block}

        would NOT contain header:

        #{expected_block}
      MESSAGE
    end

    def contain_citation_header
      citation.text.match? expected_regexp
    end

    def contain_no_citation_header
      !citation.text.match? expected_regexp
    end

    def citation
      actual.first('blockquote[type=cite]')
    end

    def citation_block
      citation.text.gsub(%r{^}, '> ')
    end

    def expected_block
      "> #{expected}"
    end

    def expected_regexp
      Regexp.new expected.gsub(' ', '([[:space:]]{1})')
    end
  end
end
