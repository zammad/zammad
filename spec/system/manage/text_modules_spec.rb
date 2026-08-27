# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Text Module', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :text_module, klass: TextModule, path: 'manage/text_modules'
  end

  context 'when selecting placeholders #6327' do
    before do
      visit 'manage/text_modules'

      within(:active_content) do
        click '[data-type="new"]'
      end
    end

    # Text modules offer no article placeholders at all, so the HTML variant must stay
    #   out as well - it could not be resolved in this context.
    it 'does not offer the HTML article placeholder' do
      in_modal do
        collection = nil

        wait.until do
          collection = page.evaluate_script("$('[data-name=\"content\"]').data().plugin_textmodule.collection")
          collection.present?
        end

        expect(collection.pluck('content')).not_to include(a_string_including('body_as_html'))
      end
    end
  end
end
