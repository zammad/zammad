# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PostmasterFilter, type: :model do
  describe '#create' do
    let(:filter) do
      {
        name:          'RSpec: PostmasterFilter#create',
        match:         matcher,
        perform:       {
          'X-Zammad-Ticket-priority' => {
            value: '3 high',
          },
        },
        channel:       'email',
        active:        true,
        created_by_id: 1,
        updated_by_id: 1,
      }
    end

    shared_examples 'raises error' do |params|
      let(:matcher) { params[:matcher] }

      it 'raises error' do
        expect { described_class.create!(filter) }.to raise_error(Exceptions::UnprocessableEntity)
      end
    end

    shared_examples 'ok' do |params|
      let(:matcher) { params[:matcher] }

      it 'ok' do
        expect(described_class.create!(filter)).to be_an(described_class)
      end
    end

    describe 'validates filter before saving' do
      context 'when valid match' do
        %w[nobody@example.com *].each do |value|
          describe "value: #{value}" do
            include_examples('ok', matcher: {
                               from: {
                                 operator: 'contains',
                                 value:    value,
                               }
                             })
          end
        end
      end

      context 'when empty match' do
        include_examples('raises error', matcher: {})
      end

      context 'when incomplete match' do
        include_examples('raises error', matcher: {
                           from: {
                             operator: 'contains',
                             value:    '',
                           }
                         })
      end

      context 'when invalid match regex' do
        %w[regex:[] regex:?? regex:*].each do |regex|
          describe regex do
            include_examples('raises error', matcher: {
                               from: {
                                 operator: 'contains',
                                 value:    regex,
                               },
                             })
          end
        end
      end
    end
  end
end
