require 'rails_helper'

RSpec.describe Stats do

  describe '#generate' do

    before do
      # create a user for which the stats can be generated
      create(:agent_user)
    end

    it 'generates stats' do
      expect { Stats.generate }.to_not raise_error
    end

    context 'when backend registration is invalid' do

      it 'fails for empty registration' do
        Setting.set('Stats::TicketWaitingTime', nil)
        expect { Stats.generate }.to raise_error(RuntimeError)
      end

      it 'fails for unknown backend' do
        Setting.set('Stats::TicketWaitingTime', 'Stats::UNKNOWN')
        expect { Stats.generate }.to raise_error(LoadError)
      end
    end
  end
end
