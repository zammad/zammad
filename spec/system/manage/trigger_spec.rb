require 'rails_helper'

RSpec.describe 'Manage > Trigger', type: :system do

  context 'Perform' do

    context 'Tags' do

      it 'shows tag selection list in foreground' do
        tag_item = create :tag_item

        visit '/#manage/trigger'
        click '.page-header-meta .btn--success'

        modal_ready

        within '.modal .ticket_perform_action' do
          find('.js-attributeSelector select').select('Tags')

          input = find('.js-value .token-input')
          input.fill_in with: tag_item.name.slice(0, 3)
        end

        expect(page).to have_css('.ui-autocomplete.ui-widget-content') { |elem| !elem.obscured? }
      end
    end
  end
end
