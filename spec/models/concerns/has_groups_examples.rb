RSpec.shared_examples 'HasGroups' do

  context 'group' do

    let(:factory_name) { described_class.name.downcase.to_sym }
    let(:instance) { create(factory_name) }
    let(:instance_inactive) { create(factory_name, active: false) }
    let(:group_full) { create(:group) }
    let(:group_read) { create(:group) }
    let(:group_inactive) { create(:group, active: false) }

    context '.group_through_identifier' do

      it 'responds to group_through_identifier' do
        expect(described_class).to respond_to(:group_through_identifier)
      end

      it 'returns a Symbol as identifier' do
        expect(described_class.group_through_identifier).to be_a(Symbol)
      end

      it 'instance responds to group_through_identifier method' do
        expect(instance).to respond_to(described_class.group_through_identifier)
      end
    end

    context '.group_through' do

      it 'responds to group_through' do
        expect(described_class).to respond_to(:group_through)
      end

      it 'returns the Reflection instance of the has_many :through relation' do
        expect(described_class.group_through).to be_a(ActiveRecord::Reflection::HasManyReflection)
      end
    end

    context '#groups' do

      it 'responds to groups' do
        expect(instance).to respond_to(:groups)
      end

      context '#groups.access' do

        it 'responds to groups.access' do
          expect(instance.groups).to respond_to(:access)
        end

        context 'result' do

          before(:each) do
            instance.group_names_access_map = {
              group_full.name     => 'full',
              group_read.name     => 'read',
              group_inactive.name => 'write',
            }
          end

          it 'returns all related Groups' do
            expect(instance.groups.access.size).to eq(3)
          end

          it 'adds join table attribute(s like) access' do
            expect(instance.groups.access.first).to respond_to(:access)
          end

          it 'filters for given access parameter' do
            expect(instance.groups.access('read')).to include(group_read)
          end

          it 'filters for given access list parameter' do
            expect(instance.groups.access('read', 'write')).to include(group_read, group_inactive)
          end

          it 'always includes full access groups' do
            expect(instance.groups.access('read')).to include(group_full)
          end
        end
      end
    end

    context '#group_access?' do

      before(:each) do
        instance.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_access?' do
        expect(instance).to respond_to(:group_access?)
      end

      context 'Group ID parameter' do
        include_examples '#group_access? call' do
          let(:group_parameter) { group_read.id }
        end
      end

      context 'Group parameter' do
        include_examples '#group_access? call' do
          let(:group_parameter) { group_read }
        end
      end

      it 'prevents inactive Group' do
        instance.group_names_access_map = {
          group_inactive.name => 'read',
        }

        expect(instance.group_access?(group_inactive.id, 'read')).to be false
      end

      it 'prevents inactive instances' do
        instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(instance_inactive.group_access?(group_read.id, 'read')).to be false
      end
    end

    context '#group_ids_access' do

      before(:each) do
        instance.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_ids_access' do
        expect(instance).to respond_to(:group_ids_access)
      end

      it 'lists only active Group IDs' do
        instance.group_names_access_map = {
          group_read.name     => 'read',
          group_inactive.name => 'read',
        }

        result = instance.group_ids_access('read')
        expect(result).not_to include(group_inactive.id)
      end

      it "doesn't list for inactive instances" do
        instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(instance_inactive.group_ids_access('read')).to be_empty
      end

      context 'single access' do

        it 'lists access Group IDs' do
          result = instance.group_ids_access('read')
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = instance.group_ids_access('write')
          expect(result).not_to include(group_read.id)
        end
      end

      context 'access list' do

        it 'lists access Group IDs' do
          result = instance.group_ids_access(%w(read write))
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = instance.group_ids_access(%w(write create))
          expect(result).not_to include(group_read.id)
        end
      end
    end

    context '#groups_access' do

      it 'responds to groups_access' do
        expect(instance).to respond_to(:groups_access)
      end

      it 'wraps #group_ids_access' do
        expect(instance).to receive(:group_ids_access)
        instance.groups_access('read')
      end

      it 'returns Groups' do
        instance.group_names_access_map = {
          group_read.name => 'read',
        }
        result = instance.groups_access('read')
        expect(result).to include(group_read)
      end
    end

    context '#group_names_access_map=' do

      it 'responds to group_names_access_map=' do
        expect(instance).to respond_to(:group_names_access_map=)
      end

      context 'Group name => access relation storage' do

        it 'stores Hash with String values' do
          expect do
            instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with String values' do
          expect do
            instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => %w(read write),
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        context 'new instance' do
          let(:new_instance) { build(factory_name) }

          it "doesn't store directly" do
            expect do
              new_instance.group_names_access_map = {
                group_full.name => 'full',
                group_read.name => 'read',
              }
            end.not_to change {
              described_class.group_through.klass.count
            }
          end

          it 'stores after save' do
            expect do
              new_instance.group_names_access_map = {
                group_full.name => 'full',
                group_read.name => 'read',
              }

              new_instance.save
            end.to change {
              described_class.group_through.klass.count
            }.by(2)
          end
        end
      end
    end

    context '#group_names_access_map' do

      it 'responds to group_names_access_map' do
        expect(instance).to respond_to(:group_names_access_map)
      end

      it 'returns instance Group name => access relations as Hash' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        instance.group_names_access_map = expected

        expect(instance.group_names_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        instance_inactive.group_names_access_map = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        expect(instance_inactive.group_names_access_map).to be_empty
      end
    end

    context '#group_ids_access_map=' do

      it 'responds to group_ids_access_map=' do
        expect(instance).to respond_to(:group_ids_access_map=)
      end

      context 'Group ID => access relation storage' do

        it 'stores Hash with String values' do
          expect do
            instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with String values' do
          expect do
            instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => %w(read write),
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        context 'new instance' do
          let(:new_instance) { build(factory_name) }

          it "doesn't store directly" do
            expect do
              new_instance.group_ids_access_map = {
                group_full.id => 'full',
                group_read.id => 'read',
              }
            end.not_to change {
              described_class.group_through.klass.count
            }
          end

          it 'stores after save' do
            expect do
              new_instance.group_ids_access_map = {
                group_full.id => 'full',
                group_read.id => 'read',
              }

              new_instance.save
            end.to change {
              described_class.group_through.klass.count
            }.by(2)
          end
        end
      end
    end

    context '#group_ids_access_map' do

      it 'responds to group_ids_access_map' do
        expect(instance).to respond_to(:group_ids_access_map)
      end

      it 'returns instance Group ID => access relations as Hash' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        instance.group_ids_access_map = expected

        expect(instance.group_ids_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        instance_inactive.group_ids_access_map = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        expect(instance_inactive.group_ids_access_map).to be_empty
      end
    end

    context '#associations_from_param' do

      it 'handles group_ids parameter as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        instance.associations_from_param(group_ids: expected)
        expect(instance.group_ids_access_map).to eq(expected)
      end

      it 'handles groups parameter as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        instance.associations_from_param(groups: expected)
        expect(instance.group_names_access_map).to eq(expected)
      end
    end

    context '#attributes_with_association_ids' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        instance.group_ids_access_map = expected

        result = instance.attributes_with_association_ids
        expect(result['group_ids']).to eq(expected)
      end
    end

    context '#attributes_with_association_names' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        instance.group_ids_access_map = expected

        result = instance.attributes_with_association_names
        expect(result['group_ids']).to eq(expected)
      end

      it 'includes groups as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        instance.group_names_access_map = expected

        result = instance.attributes_with_association_names
        expect(result['groups']).to eq(expected)
      end
    end

    context '.group_access_ids' do

      before(:each) do
        instance.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_access_ids' do
        expect(described_class).to respond_to(:group_access_ids)
      end

      it 'lists only active instance IDs' do
        instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access_ids(group_read.id, 'read')
        expect(result).not_to include(instance_inactive.id)
      end

      context 'Group ID parameter' do
        include_examples '.group_access_ids call' do
          let(:group_parameter) { group_read.id }
        end
      end

      context 'Group parameter' do
        include_examples '.group_access_ids call' do
          let(:group_parameter) { group_read.id }
        end
      end
    end

    context '.group_access' do

      it 'responds to group_access' do
        expect(described_class).to respond_to(:group_access)
      end

      it 'wraps .group_access_ids' do
        expect(described_class).to receive(:group_access_ids)
        described_class.group_access(group_read, 'read')
      end

      it 'returns class instances' do
        instance.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access(group_read, 'read')
        expect(result).to include(instance)
      end
    end

    it 'destroys relations before instance gets destroyed' do

      instance.group_names_access_map = {
        group_full.name     => 'full',
        group_read.name     => 'read',
        group_inactive.name => 'write',
      }
      expect do
        instance.destroy
      end.to change {
        described_class.group_through.klass.count
      }.by(-3)
    end
  end
end

RSpec.shared_examples '#group_access? call' do
  context 'single access' do

    it 'checks positive' do
      expect(instance.group_access?(group_parameter, 'read')).to be true
    end

    it 'checks negative' do
      expect(instance.group_access?(group_parameter, 'write')).to be false
    end
  end

  context 'access list' do

    it 'checks positive' do
      expect(instance.group_access?(group_parameter, %w(read write))).to be true
    end

    it 'checks negative' do
      expect(instance.group_access?(group_parameter, %w(write create))).to be false
    end
  end
end

RSpec.shared_examples '.group_access_ids call' do
  context 'single access' do

    it 'lists access IDs' do
      expect(described_class.group_access_ids(group_parameter, 'read')).to include(instance.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access_ids(group_parameter, 'write')).not_to include(instance.id)
    end
  end

  context 'access list' do

    it 'lists access IDs' do
      expect(described_class.group_access_ids(group_parameter, %w(read write))).to include(instance.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access_ids(group_parameter, %w(write create))).not_to include(instance.id)
    end
  end
end
