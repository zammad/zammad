# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Add Article Hint', authenticated_as: :authenticate, type: :system do
  def authenticate
    Setting.set 'ui_ticket_add_article_hint', {
      'note-internal': 'internal note',
      'note-public':   'public note',
      'phone-public':  'public phone',
    }

    user
  end

  let(:user) { create(:agent, groups: [Ticket.first.group]) }

  context 'with a fresh article' do
    before do
      visit "#ticket/zoom/#{Ticket.first.id}"
    end

    it 'shows hint for the selected type' do
      within '.article-new' do
        expect { click '.attachmentPlaceholder' }
          .to change { page.has_text?('internal note', wait: 0) }
          .to true
      end
    end

    it 'changes hint when changing visibility' do
      within '.article-new' do
        click '.attachmentPlaceholder'
        click '.js-toggleVisibility'

        expect(page).to have_text 'public note'
      end
    end

    it 'changes hint when changing type' do
      within '.article-new' do
        click '.attachmentPlaceholder'

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value=phone]'

        expect(page).to have_text 'public phone'
      end
    end

    it 'hides hint when changing to type that has no hint' do
      within '.article-new' do
        click '.attachmentPlaceholder'

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value=email]'

        expect(page).to have_no_css '.article-visibility-text'
      end
    end
  end

  context 'with a taskbar' do
    before do
      create(:taskbar,
             key:     "Ticket-#{Ticket.first.id}",
             user_id: user.id,
             state:   { ticket: {}, article: article_payload })

      visit "#ticket/zoom/#{Ticket.first.id}"
    end

    context 'when selected type has a hint' do
      let(:article_payload) { { type: :phone, internal: false } }

      it 'shows a hint' do
        within :active_content do
          click '.attachmentPlaceholder'
          expect(page).to have_text 'public phone'
        end
      end

      it 'hides the hint when changing to visibility that has no hint' do
        within '.article-new' do
          click '.attachmentPlaceholder'
          click '.js-toggleVisibility'

          expect(page).to have_no_css '.article-visibility-text'
        end
      end
    end

    context 'when selected type has no hint' do
      let(:article_payload) { { type: :email, internal: false } }

      it 'shows no hint' do
        within :active_content do
          click '.attachmentPlaceholder'

          expect(page).to have_no_css '.article-visibility-text'
        end
      end
    end
  end
end
