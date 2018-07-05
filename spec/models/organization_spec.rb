require 'rails_helper'
require 'models/concerns/can_lookup_examples'

RSpec.describe Organization do
  include_examples 'CanLookup'

  context '.where_or_cis' do

    it 'finds instance by querying multiple attributes case insensitive' do
      # search for Zammad Foundation
      organizations = described_class.where_or_cis(%i[name note], '%zammad%')
      expect(organizations).not_to be_blank
    end
  end
end
