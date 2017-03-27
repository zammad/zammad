require 'rails_helper'

RSpec.describe Ticket::State do

  context '.by_category' do

    it 'looks up states by category' do
      result = described_class.by_category(:open)
      expect(result).to be_an(ActiveRecord::Relation)
      expect(result).to_not be_empty
      expect(result.first).to be_a(Ticket::State)
    end

    it 'raises RuntimeError for invalid category' do
      expect { described_class.by_category(:invalidcategoryname) }.to raise_error(RuntimeError)
    end
  end
end
