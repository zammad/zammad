require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Ticket::State, type: :model do
  include_examples 'ApplicationModel'

  describe '.by_category' do
    it 'looks up states by category' do
      expect(described_class.by_category(:open))
        .to be_an(ActiveRecord::Relation)
        .and include(instance_of(Ticket::State))
    end

    context 'with invalid category name' do
      it 'raises RuntimeError' do
        expect { described_class.by_category(:invalidcategoryname) }
          .to raise_error(RuntimeError)
      end
    end
  end
end
