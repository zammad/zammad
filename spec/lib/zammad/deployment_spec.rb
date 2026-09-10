# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::Deployment do
  before do
    allow(ENV).to receive(:[]).with('ZAMMAD_DOCKER').and_return(env_value)
  end

  describe '.container?' do
    subject(:container) { described_class.container? }

    context 'without ZAMMAD_DOCKER' do
      let(:env_value) { nil }

      it { is_expected.to be false }
    end

    # The Dockerfile sets 'true'; '1' is accepted for hand-written container setups.
    %w[1 true].each do |value|
      context "with ZAMMAD_DOCKER set to #{value.inspect}" do
        let(:env_value) { value }

        it { is_expected.to be true }
      end
    end

    # Only the documented values count, so that an explicit opt-out is not misread as a container.
    ['0', 'false', '', 'yes', 'docker'].each do |value|
      context "with ZAMMAD_DOCKER set to #{value.inspect}" do
        let(:env_value) { value }

        it { is_expected.to be false }
      end
    end
  end
end
