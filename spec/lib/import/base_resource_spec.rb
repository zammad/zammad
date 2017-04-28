require 'rails_helper'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe Import::BaseResource do

  it "needs an implementation of the 'import_class' method" do
    expect {
      described_class.new(attributes_for(:group))
    }.to raise_error(NoMethodError)
  end

  context "implemented 'import_class' method" do

    before do
      module Import
        module Test
          class Group < Import::BaseResource

            def import_class
              ::Group
            end

            def source
              'RSpec-TEST'
            end
          end
        end
      end
    end

    after do
      Import::Test.send(:remove_const, :Group)
    end

    let(:attributes) {
      attributes      = attributes_for(:group)
      attributes[:id] = 1337
      attributes
    }

    context 'live run' do

      it 'creates new resources' do
        expect do
          Import::Test::Group.new(attributes)
        end
          .to change {
            Group.count
          }.by(1)
          .and change {
            ExternalSync.count
          }.by(1)
      end

      it 'updates existing resources' do

        # initial import
        Import::Test::Group.new(attributes)
        group = Group.last

        # simulate next import run
        travel 20.minutes

        attributes[:note] = 'TEST'

        expect do
          Import::Test::Group.new(attributes)
          group.reload
        end
          .to change {
            group.note
          }
      end
    end

    context 'dry run' do

      it "doesn't create new resources" do
        expect do
          Import::Test::Group.new(attributes, dry_run: true)
        end
          .to not_change {
            Group.count
          }
          .and not_change {
            ExternalSync.count
          }
      end

      it "doesn't update existing resources" do

        # initial import
        Import::Test::Group.new(attributes)
        group = Group.last

        # simulate next import run
        travel 20.minutes

        attributes[:note] = 'TEST'

        expect do
          Import::Test::Group.new(attributes, dry_run: true)
          group.reload
        end
          .to not_change {
            group.note
          }
          .and not_change {
            Group.count
          }
          .and not_change {
            ExternalSync.count
          }
      end
    end
  end

end
