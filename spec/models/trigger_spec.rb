require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Trigger, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }

  subject(:trigger) { create(:trigger) }

  describe '#assets (for supplying model data to front-end framework)' do
    subject(:trigger) { create(:trigger, condition: condition, perform: perform) }
    let(:condition) { { 'ticket.state_id' => { operator: 'is', value: 1 } } }
    let(:perform) { { 'ticket.priority_id' => { value: 1 } } }

    it 'returns a hash with asset attributes for objects referenced in #condition and #perform' do
      expect(trigger.assets({}))
        .to include(Ticket::State.first.assets({}))
        .and include(Ticket::Priority.first.assets({}))
    end
  end
end
