require 'rails_helper'

RSpec.describe Organization do

  context '.where_or_cis' do

    it 'finds instance by querying multiple attributes case insensitive' do
      # search for Zammad Foundation
      organizations = described_class.where_or_cis(%i[name note], '%zammad%')
      expect(organizations).not_to be_blank
    end
  end
end
