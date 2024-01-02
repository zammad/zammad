# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OperationsRateLimiter do
  before { freeze_time }

  describe '#ensure_within_limits!' do
    context 'with an IP address' do
      it 'passes' do
        expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4') }
          .not_to raise_error
      end

      context 'with many operations' do
        before do
          5.times do
            described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4')
          end
        end

        it 'raises error due to too many operations from same IP in short time' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4') }
            .to raise_error(described_class::ThrottleLimitExceeded)
        end

        it 'passes after period is over' do
          travel 2.hours

          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4') }
            .not_to raise_error
        end

        it 'passes with a different IP address' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7') }
            .not_to raise_error
        end
      end
    end

    context 'with a field' do
      it 'passes' do
        expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4', by_identifier: 'bar') }
          .not_to raise_error
      end

      context 'with many operations' do
        before do
          5.times do
            described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '1.2.3.4', by_identifier: 'bar')
          end
        end

        it 'raises error due too many operations with the same value from different IPs' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7', by_identifier: 'bar') }
            .to raise_error(described_class::ThrottleLimitExceeded)
        end

        it 'raises error due too many operations with upercase value' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7', by_identifier: 'BAR') }
            .to raise_error(described_class::ThrottleLimitExceeded)
        end

        it 'raises error due too many operations with trailing space' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7', by_identifier: 'bar ') }
            .to raise_error(described_class::ThrottleLimitExceeded)
        end

        it 'passes after period is over' do
          travel 2.hours

          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7', by_identifier: 'bar') }
            .not_to raise_error
        end

        it 'passes with a different value' do
          expect { described_class.new(limit: 5, period: 1.hour, operation: 'test').ensure_within_limits!(by_ip: '4.5.6.7', by_identifier: 'baz') }
            .not_to raise_error
        end
      end
    end
  end
end
