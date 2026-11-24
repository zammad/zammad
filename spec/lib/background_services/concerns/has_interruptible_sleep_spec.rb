# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe BackgroundServices::Concerns::HasInterruptibleSleep do
  subject(:sleeper) { Class.new { include BackgroundServices::Concerns::HasInterruptibleSleep }.new }

  let(:steps) { [] }

  before do
    allow(sleeper).to receive(:sleep) { |step| steps << step }
  end

  describe '#interruptible_sleep' do
    it 'sleeps a whole number of seconds in steps of one second' do
      sleeper.interruptible_sleep(3)

      expect(steps).to eq([1, 1, 1])
    end

    it 'sleeps a duration' do
      sleeper.interruptible_sleep(2.seconds)

      expect(steps).to eq([1, 1])
    end

    it 'sleeps a fraction of a second as the last step' do
      sleeper.interruptible_sleep(2.5)

      expect(steps).to eq([1, 1, 0.5])
    end

    it 'sleeps less than a second in one step' do
      sleeper.interruptible_sleep(0.25)

      expect(steps).to eq([0.25])
    end

    it 'does not sleep for zero seconds' do
      sleeper.interruptible_sleep(0)

      expect(steps).to be_empty
    end

    context 'when shutdown is requested while sleeping' do
      before do
        allow(BackgroundServices).to receive(:shutdown_requested).and_return(false, true)
      end

      it 'stops after the current step' do
        sleeper.interruptible_sleep(3.5)

        expect(steps).to eq([1])
      end
    end
  end
end
