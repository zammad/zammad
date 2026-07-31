# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'AI > Feedback & Logs', authenticated_as: :admin, type: :system do
  let(:admin) { create(:admin) }

  it 'downloads feedback and error logs' do
    visit '/#ai/feedback_logs'

    within :active_content do
      expect(page).to have_text('Download feedback from agents on AI features and error details about failed AI requests.')

      click '.js-downloadFeedback'

      click '.js-downloadErrorLogs'

      # we can't test the download itself, but we can check if the button is still there so we didn't redirect
      expect(page).to have_text('DOWNLOAD FEEDBACK')
        .and have_text('DOWNLOAD ERROR LOGS')
    end
  end

  describe 'the log reference' do
    let(:connection) { create(:ai_provider_connection, name: 'Main OpenAI') }

    it 'links to the connection that caused the request' do
      create(:http_log, facility: 'AI::Provider', related_object: connection)

      visit '/#ai/feedback_logs'

      within :active_content do
        # Table headers are uppercased by CSS, and Capybara matches the rendered text.
        expect(page).to have_text('CAUSED BY')
        expect(page).to have_css('.js-relatedObject', text: 'Main OpenAI')
        expect(find('.js-relatedObject')[:href]).to end_with("#ai/providers/1/id:#{connection.id}")
      end
    end

    # Entries from before the reference existed sit next to ones that have it, and a blank cell
    # would read as a rendering glitch rather than as "nothing caused this".
    it 'shows a dash for a log without a reference' do
      referenced   = create(:http_log, facility: 'AI::Provider', related_object: connection)
      unreferenced = create(:http_log, facility: 'AI::Provider')

      visit '/#ai/feedback_logs'

      within :active_content do
        # By column position, so this also covers the reference staying in its own cell.
        expect(find("tr[data-id='#{referenced.id}'] td:nth-child(3)")).to have_link('Main OpenAI')
        expect(find("tr[data-id='#{unreferenced.id}'] td:nth-child(3)").text).to eq('-')
      end
    end

    # Most facilities never set a reference, so they must not get a permanently empty column.
    it 'omits the column when no log has a reference' do
      create(:http_log, facility: 'AI::Provider')

      visit '/#ai/feedback_logs'

      within :active_content do
        expect(page).to have_css('.settings-list')
        expect(page).to have_no_text('CAUSED BY')
      end
    end

    context 'with a delegated administrator without provider permission' do
      let(:role)            { create(:role, permission_names: %w[admin.ai_feedback_logs]) }
      let(:delegated_admin) { create(:agent, roles: [role]) }

      # Following the link would only bounce off permissionCheckRedirect, so it is not offered.
      it 'names the connection without linking it', authenticated_as: :delegated_admin do
        create(:http_log, facility: 'AI::Provider', related_object: connection)

        visit '/#ai/feedback_logs'

        within :active_content do
          expect(page).to have_text('CAUSED BY')
          expect(page).to have_text('Main OpenAI')
          expect(page).to have_no_css('.js-relatedObject')
        end
      end
    end
  end
end
