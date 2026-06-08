# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    shared_examples 'raises exception' do |params|
      let(:matcher) { params[:matcher] }

      it 'raises exception' do
        expect { described_class.create!(filter) }.to raise_exception(an_instance_of(Exceptions::InvalidAttribute).and(have_attributes(attribute: 'match', message: start_with(params[:message]))))
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
        include_examples('raises exception', matcher: {}, message: 'At least one match rule is required, but none was provided.')
      end

      context 'when incomplete match' do
        include_examples('raises exception', matcher: {
                           from: {
                             operator: 'contains',
                             value:    '',
                           }
                         }, message: 'The required match value is missing.')
      end

      context 'when invalid match regex' do
        %w[[] ?? *].each do |regex|
          describe regex do
            include_examples('raises exception', matcher: {
                               from: {
                                 operator: 'matches regex',
                                 value:    regex,
                               },
                             }, message: "Can't use regex '#{regex}'")
          end
        end
      end
    end
  end
end
