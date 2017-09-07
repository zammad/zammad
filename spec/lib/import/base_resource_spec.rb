require 'rails_helper'

RSpec.describe Import::BaseResource do

  it "needs an implementation of the 'import_class' method" do
    expect {
      described_class.new(attributes_for(:group))
    }.to raise_error(NoMethodError)
  end

  context "implemented 'import_class' method" do

    before do
      module Import
        class Test < Import::Base
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

      it "doesn't update associations of existing resources" do

        # initial import
        Import::Test::Group.new(attributes)
        group = Group.last

        old_signature = create(:signature)
        old_users     = create_list(:user, 2)

        group.update_attribute(:signature_id, old_signature.id)
        group.update_attribute(:user_ids, old_users.collect(&:id))

        # simulate next import run
        travel 20.minutes

        new_signature             = create(:signature)
        new_users                 = create_list(:user, 2)
        attributes[:signature_id] = new_signature.id
        attributes[:user_ids]     = new_users.collect(&:id)

        expect do
          Import::Test::Group.new(attributes, dry_run: true)
          group.reload
        end
          .to not_change {
            group.signature_id
          }
          .and not_change {
            group.user_ids
          }
      end
    end
  end

end
