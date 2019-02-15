require 'rails_helper'
require 'models/concerns/can_lookup_examples'
require 'models/concerns/has_search_index_backend_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Organization, type: :model do
  it_behaves_like 'CanLookup'
  it_behaves_like 'HasSearchIndexBackend', indexed_factory: :organization
  it_behaves_like 'HasXssSanitizedNote', model_factory: :organization

  describe '.where_or_cis' do
    it 'finds instance by querying multiple attributes case insensitive' do
      # search for Zammad Foundation
      organizations = described_class.where_or_cis(%i[name note], '%zammad%')
      expect(organizations).not_to be_blank
    end
  end

end
