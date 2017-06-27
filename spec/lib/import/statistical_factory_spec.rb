require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::StatisticalFactory do
  it_behaves_like 'Import::Factory'

  before do
    module Import
      class Test < Import::Base

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

    context 'live run' do

      it 'tracks created instances' do

        Import::Test::GroupFactory.import([attributes])

        statistics = {
          created:     1,
          updated:     0,
          unchanged:   0,
          skipped:     0,
          failed:      0,
          deactivated: 0,
        }
        expect(Import::Test::GroupFactory.statistics).to eq(statistics)
      end

      context 'updated instances' do
        it 'tracks by regular attributes' do

          Import::Test::GroupFactory.import([attributes])

          # simulate next import run
          travel 20.minutes
          Import::Test::GroupFactory.reset_statistics

          attributes[:note] = 'TEST'
          Import::Test::GroupFactory.import([attributes])

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end

        it 'tracks by has_many association attributes' do

          Import::Test::GroupFactory.import([attributes])

          # simulate next import run
          travel 20.minutes
          Import::Test::GroupFactory.reset_statistics

          new_users             = create_list(:user, 2)
          attributes[:user_ids] = new_users.collect(&:id)

          Import::Test::GroupFactory.import([attributes])

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end

        it 'tracks by belongs_to association attributes' do

          Import::Test::GroupFactory.import([attributes])

          # simulate next import run
          travel 20.minutes
          Import::Test::GroupFactory.reset_statistics

          new_signature             = create(:signature)
          attributes[:signature_id] = new_signature.id

          Import::Test::GroupFactory.import([attributes])

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end
      end

      it 'tracks unchanged instances' do

        Import::Test::GroupFactory.import([attributes])

        # simulate next import run
        travel 20.minutes
        Import::Test::GroupFactory.reset_statistics

        Import::Test::GroupFactory.import([attributes])

        statistics = {
          created:     0,
          updated:     0,
          unchanged:   1,
          skipped:     0,
          failed:      0,
          deactivated: 0,
        }
        expect(Import::Test::GroupFactory.statistics).to eq(statistics)
      end
    end

    context 'dry run' do

      it 'tracks created instances' do

        Import::Test::GroupFactory.import([attributes], dry_run: true)

        statistics = {
          created:     1,
          updated:     0,
          unchanged:   0,
          skipped:     0,
          failed:      0,
          deactivated: 0,
        }
        expect(Import::Test::GroupFactory.statistics).to eq(statistics)
      end

      context 'updated instances' do

        let(:local_group) { create(:group) }

        before(:each) do
          ExternalSync.create(
            source:    'RSpec-Test',
            source_id: local_group.id,
            object:    'Group',
            o_id:      local_group.id
          )
        end

        it 'tracks by regular attributes' do

          update_attributes        = local_group.attributes
          update_attributes[:note] = 'TEST'

          Import::Test::GroupFactory.import([update_attributes], dry_run: true)

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end

        it 'tracks by has_many association attributes' do

          update_attributes            = local_group.attributes
          new_users                    = create_list(:user, 2)
          update_attributes[:user_ids] = new_users.collect(&:id)

          Import::Test::GroupFactory.import([update_attributes], dry_run: true)

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end

        it 'tracks by belongs_to association attributes' do

          update_attributes                = local_group.attributes
          new_signature                    = create(:signature)
          update_attributes[:signature_id] = new_signature.id

          Import::Test::GroupFactory.import([update_attributes], dry_run: true)

          statistics = {
            created:     0,
            updated:     1,
            unchanged:   0,
            skipped:     0,
            failed:      0,
            deactivated: 0,
          }
          expect(Import::Test::GroupFactory.statistics).to eq(statistics)
        end
      end

      it 'tracks unchanged instances' do

        local_group = create(:group)

        ExternalSync.create(
          source:    'RSpec-Test',
          source_id: local_group.id,
          object:    'Group',
          o_id:      local_group.id
        )

        Import::Test::GroupFactory.import([local_group.attributes], dry_run: true)

        statistics = {
          created:     0,
          updated:     0,
          unchanged:   1,
          skipped:     0,
          failed:      0,
          deactivated: 0,
        }
        expect(Import::Test::GroupFactory.statistics).to eq(statistics)
      end
    end
  end
end
