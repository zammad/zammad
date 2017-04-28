require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::StatisticalFactory do
  it_behaves_like 'Import::Factory'

  before do
    module Import
      module Test

        module GroupFactory
          extend Import::StatisticalFactory
        end

        class Group < Import::ModelResource
          def source
            'RSpec-Test'
          end
        end
      end
    end
  end

  after do
    Import::Test.send(:remove_const, :GroupFactory)
    Import::Test.send(:remove_const, :Group)
  end

  before(:each) do
    Import::Test::GroupFactory.reset_statistics
  end

  let(:attributes) {
    attributes = attributes_for(:group)
    attributes[:id] = 1337
    attributes
  }

  context 'statistics' do

    it 'tracks created instances' do

      Import::Test::GroupFactory.import([attributes])

      statistics = {
        created:   1,
        updated:   0,
        unchanged: 0,
        skipped:   0,
        failed:    0,
      }
      expect(Import::Test::GroupFactory.statistics).to eq(statistics)
    end

    it 'tracks updated instances' do

      Import::Test::GroupFactory.import([attributes])

      # simulate next import run
      travel 20.minutes
      Import::Test::GroupFactory.reset_statistics

      attributes[:note] = 'TEST'
      Import::Test::GroupFactory.import([attributes])

      statistics = {
        created:   0,
        updated:   1,
        unchanged: 0,
        skipped:   0,
        failed:    0,
      }
      expect(Import::Test::GroupFactory.statistics).to eq(statistics)
    end

    it 'tracks unchanged instances' do

      Import::Test::GroupFactory.import([attributes])

      # simulate next import run
      travel 20.minutes
      Import::Test::GroupFactory.reset_statistics

      Import::Test::GroupFactory.import([attributes])

      statistics = {
        created:   0,
        updated:   0,
        unchanged: 1,
        skipped:   0,
        failed:    0,
      }
      expect(Import::Test::GroupFactory.statistics).to eq(statistics)
    end
  end
end
