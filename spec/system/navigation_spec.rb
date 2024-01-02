# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Navigation', type: :system do
  before { visit '/' }

  context 'when mobile', screen_size: :mobile do
    it 'widens navigation bar on clicking button' do
      expect { click '.js-navigation-toggle-button' }
        .to change { navigation_collapsed? }
        .to(false)
    end

    it 'widens navigation bar on opening search' do
      expect { click '#global-search' }
        .to change { navigation_collapsed? }
        .to(false)
    end
  end

  context 'when tablet', screen_size: :tablet do
    it 'collapses navigation bar on clicking button' do
      expect { click '.js-navigation-toggle-button' }
        .to change { navigation_collapsed? }
        .to(true)
    end
  end

  context 'when desktop', screen_size: :desktop do
    it 'does not show collapse button' do
      expect(page).to have_no_css '.js-navigation-toggle-button'
    end

    it 'shows full navigation bar' do
      expect(navigation_collapsed?).to be_falsey
    end
  end

  def navigation_current_width
    evaluate_script("$('#navigation').width()")
  end

  def navigation_collapsed?
    navigation_current_width == 50
  end
end
