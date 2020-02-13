require 'rails_helper'

RSpec.describe Chat, type: :model do

  describe 'website whitelisting' do
    let(:chat) { create(:chat, whitelisted_websites: 'zammad.org') }

    it 'detects whitelisted website' do
      result = chat.website_whitelisted?('https://www.zammad.org')
      expect(result).to be true
    end

    it 'detects non-whitelisted website' do
      result = chat.website_whitelisted?('https://www.zammad.com')
      expect(result).to be false
    end
  end
end
