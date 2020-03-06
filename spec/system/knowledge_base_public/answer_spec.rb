require 'rails_helper'

RSpec.describe 'Public Knowledge Base answer', type: :system, authenticated: false do
  include_context 'basic Knowledge Base'

  context 'video content' do

    before do
      published_answer_with_video
    end

    it 'shows video player' do
      visit help_answer_path(primary_locale.system_locale.locale, category, published_answer_with_video)

      iframe = find('iframe')
      expect(iframe['src']).to start_with('https://www.youtube.com/embed/')
    end
  end
end
