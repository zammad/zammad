require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/sub_sequence/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::OrganizationFields, sequencer: :unit do
  include_examples 'Sequencer::Unit::Import::Zendesk::SubSequence::Base'
end
