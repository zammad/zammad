# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The preferences are planted directly via the factory, deliberately bypassing the
#   write-path filtering, so the rendering is verified independently.
RSpec.describe 'Ticket zoom > Article preferences rendering', authenticated_as: :agent, type: :system do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group: group) }

  context 'with an unexpected security.type value' do
    let(:article) do
      create(:ticket_article, ticket: ticket, preferences: {
               security: {
                 type:       '<img src=x onerror="window.xssFired=true" id="xss-security">',
                 encryption: { success: true, comment: 'c' },
                 sign:       { success: false, comment: nil },
               },
             })
    end

    it 'renders the type as text and does not execute markup' do
      visit "#ticket/zoom/#{article.ticket.id}"

      open_article_meta

      within :active_ticket_article, article do
        # The security row must actually be rendered, so the check below is not vacuous.
        expect(page).to have_css('.article-meta-value', text: 'onerror', visible: :all)
        expect(page).to have_no_css('#xss-security', visible: :all)
      end

      expect(page.evaluate_script('window.xssFired')).to be_nil
    end
  end

  context 'with an unsafe link url' do
    let(:article) do
      create(:ticket_article, ticket: ticket, preferences: {
               links: [{ url: 'javascript:window.xssFired=true//', target: '_blank', name: 'evil' }],
             })
    end

    it 'neutralizes the unsafe href' do
      visit "#ticket/zoom/#{article.ticket.id}"

      open_article_meta

      within :active_ticket_article, article do
        link = find('.article-meta-links a', text: 'evil')
        expect(link[:href].to_s).not_to start_with('javascript:')
      end
    end
  end
end
