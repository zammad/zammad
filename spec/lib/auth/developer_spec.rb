# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend_examples'

RSpec.describe Auth::Developer do

  let(:user) { create(:user) }
  let(:instance) { described_class.new({ adapter: described_class.name }) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'

    it "authenticates users with password 'test'" do

      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).with('developer_mode').and_return(true)

      result = instance.valid?(user, 'test')

      expect(result).to be true
    end

    context 'invalid' do

      let(:password) { 'zammad' }

      it "doesn't authenticate if developer mode is off" do

        allow(Setting).to receive(:get)
        allow(Setting).to receive(:get).with('developer_mode').and_return(false)

        result = instance.valid?(user, password)

        expect(result).to be false
      end

      it "doesn't authenticate with correct password" do

        allow(Setting).to receive(:get)
        allow(Setting).to receive(:get).with('developer_mode').and_return(true)

        result = instance.valid?(user, password)

        expect(result).to be false
      end
    end
  end
end
