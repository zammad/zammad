require 'rails_helper'
require 'lib/auth/backend_examples'

RSpec.describe Auth::Base do

  let(:user) { create(:user) }
  let(:instance) { described_class.new({ adapter: described_class.name }) }

  context '#valid?' do
    it_behaves_like 'Auth backend'

    it "requires an implementation of the 'valid?' method" do

      expect do
        instance.valid?(user, 'password')
      end.to raise_error(RuntimeError)
    end
  end
end
