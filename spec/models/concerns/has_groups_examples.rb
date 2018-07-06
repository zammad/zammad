# Requires: let(:group_access_instance) { ... }
# Requires: let(:new_group_access_instance) { ... }
RSpec.shared_examples 'HasGroups' do

  context 'group' do
    let(:group_access_instance_inactive) do
      group_access_instance.update!(active: false)
      group_access_instance
    end
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
        expect(group_access_instance).to respond_to(described_class.group_through_identifier)
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
        expect(group_access_instance).to respond_to(:groups)
      end

      context '#groups.access' do

        it 'responds to groups.access' do
          expect(group_access_instance.groups).to respond_to(:access)
        end

        context 'result' do

          before(:each) do
            group_access_instance.group_names_access_map = {
              group_full.name     => 'full',
              group_read.name     => 'read',
              group_inactive.name => 'change',
            }
          end

          it 'returns all related Groups' do
            expect(group_access_instance.groups.access.size).to eq(3)
          end

          it 'adds join table attribute(s like) access' do
            expect(group_access_instance.groups.access.first).to respond_to(:access)
          end

          it 'filters for given access parameter' do
            expect(group_access_instance.groups.access('read')).to include(group_read)
          end

          it 'filters for given access list parameter' do
            expect(group_access_instance.groups.access('read', 'change')).to include(group_read, group_inactive)
          end

          it 'always includes full access groups' do
            expect(group_access_instance.groups.access('read')).to include(group_full)
          end
        end
      end
    end

    context '#group_access?' do

      it 'responds to group_access?' do
        expect(group_access_instance).to respond_to(:group_access?)
      end

      before(:each) do
        group_access_instance.group_names_access_map = {
          group_read.name => 'read',
        }
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
        group_access_instance.group_names_access_map = {
          group_inactive.name => 'read',
        }

        expect(group_access_instance.group_access?(group_inactive.id, 'read')).to be false
      end

      it 'prevents inactive instances' do
        group_access_instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(group_access_instance_inactive.group_access?(group_read.id, 'read')).to be false
      end
    end

    context '#group_ids_access' do

      it 'responds to group_ids_access' do
        expect(group_access_instance).to respond_to(:group_ids_access)
      end

      before(:each) do
        group_access_instance.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'lists only active Group IDs' do
        group_access_instance.group_names_access_map = {
          group_read.name     => 'read',
          group_inactive.name => 'read',
        }

        result = group_access_instance.group_ids_access('read')
        expect(result).not_to include(group_inactive.id)
      end

      it "doesn't list for inactive instances" do
        group_access_instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(group_access_instance_inactive.group_ids_access('read')).to be_empty
      end

      context 'single access' do

        it 'lists access Group IDs' do
          result = group_access_instance.group_ids_access('read')
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = group_access_instance.group_ids_access('change')
          expect(result).not_to include(group_read.id)
        end
      end

      context 'access list' do

        it 'lists access Group IDs' do
          result = group_access_instance.group_ids_access(%w[read change])
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = group_access_instance.group_ids_access(%w[change create])
          expect(result).not_to include(group_read.id)
        end
      end
    end

    context '#groups_access' do

      it 'responds to groups_access' do
        expect(group_access_instance).to respond_to(:groups_access)
      end

      it 'wraps #group_ids_access' do
        expect(group_access_instance).to receive(:group_ids_access)
        group_access_instance.groups_access('read')
      end

      it 'returns Groups' do
        group_access_instance.group_names_access_map = {
          group_read.name => 'read',
        }
        result = group_access_instance.groups_access('read')
        expect(result).to include(group_read)
      end
    end

    context '#group_names_access_map=' do

      it 'responds to group_names_access_map=' do
        expect(group_access_instance).to respond_to(:group_names_access_map=)
      end

      context 'existing instance' do

        it 'stores Hash with String values' do
          expect do
            group_access_instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with Array<String> values' do
          expect do
            group_access_instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => %w[read change],
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        it 'allows empty Hash value' do
          group_access_instance.group_names_access_map = {
            group_full.name => 'full',
            group_read.name => %w[read change],
          }

          expect do
            group_access_instance.group_names_access_map = {}
          end.to change {
            described_class.group_through.klass.count
          }.by(-3)
        end

        it 'prevents having full and other privilege at the same time' do

          invalid_combination = %w[full read change]
          exception           = ActiveRecord::RecordInvalid

          expect do
            group_access_instance.group_names_access_map = {
              group_full.name => invalid_combination,
            }
          end.to raise_error(exception)

          expect do
            group_access_instance.group_names_access_map = {
              group_full.name => invalid_combination.reverse,
            }
          end.to raise_error(exception)
        end
      end

      context 'new instance' do

        it "doesn't store directly" do
          expect do
            new_group_access_instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }
          end.not_to change {
            described_class.group_through.klass.count
          }
        end

        it 'stores after save' do
          expect do
            new_group_access_instance.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }

            new_group_access_instance.save
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'allows empty Hash value' do
          expect do
            new_group_access_instance.group_names_access_map = {}

            new_group_access_instance.save
          end.not_to change {
            described_class.group_through.klass.count
          }
        end
      end
    end

    context '#group_names_access_map' do

      it 'responds to group_names_access_map' do
        expect(group_access_instance).to respond_to(:group_names_access_map)
      end

      it 'returns instance Group name => access relations as Hash' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        group_access_instance.group_names_access_map = expected

        expect(group_access_instance.group_names_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        group_access_instance_inactive.group_names_access_map = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        expect(group_access_instance_inactive.group_names_access_map).to be_empty
      end

      it 'returns empty map if none is stored' do

        group_access_instance.group_names_access_map = {
          group_full.name => 'full',
          group_read.name => 'read',
        }

        group_access_instance.group_names_access_map = {}

        expect(group_access_instance.group_names_access_map).to be_blank
      end
    end

    context '#group_ids_access_map=' do

      it 'responds to group_ids_access_map=' do
        expect(group_access_instance).to respond_to(:group_ids_access_map=)
      end

      context 'existing instance' do

        it 'stores Hash with String values' do
          expect do
            group_access_instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with Array<String> values' do
          expect do
            group_access_instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => %w[read change],
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        it 'allows empty Hash value' do
          group_access_instance.group_ids_access_map = {
            group_full.id => 'full',
            group_read.id => %w[read change],
          }

          expect do
            group_access_instance.group_ids_access_map = {}
          end.to change {
            described_class.group_through.klass.count
          }.by(-3)
        end
      end

      context 'new instance' do

        it "doesn't store directly" do
          expect do
            new_group_access_instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }
          end.not_to change {
            described_class.group_through.klass.count
          }
        end

        it 'stores after save' do
          expect do
            new_group_access_instance.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }

            new_group_access_instance.save
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'allows empty Hash value' do
          expect do
            new_group_access_instance.group_ids_access_map = {}

            new_group_access_instance.save
          end.not_to change {
            described_class.group_through.klass.count
          }
        end
      end
    end

    context '#group_ids_access_map' do

      it 'responds to group_ids_access_map' do
        expect(group_access_instance).to respond_to(:group_ids_access_map)
      end

      it 'returns instance Group ID => access relations as Hash' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        group_access_instance.group_ids_access_map = expected

        expect(group_access_instance.group_ids_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        group_access_instance_inactive.group_ids_access_map = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        expect(group_access_instance_inactive.group_ids_access_map).to be_empty
      end

      it 'returns empty map if none is stored' do

        group_access_instance.group_ids_access_map = {
          group_full.id => 'full',
          group_read.id => 'read',
        }

        group_access_instance.group_ids_access_map = {}

        expect(group_access_instance.group_ids_access_map).to be_blank
      end
    end

    context '#associations_from_param' do

      it 'handles group_ids parameter as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        group_access_instance.associations_from_param(group_ids: expected)
        expect(group_access_instance.group_ids_access_map).to eq(expected)
      end

      it 'handles groups parameter as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        group_access_instance.associations_from_param(groups: expected)
        expect(group_access_instance.group_names_access_map).to eq(expected)
      end
    end

    context '#attributes_with_association_ids' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        group_access_instance.group_ids_access_map = expected

        result = group_access_instance.attributes_with_association_ids
        expect(result['group_ids']).to eq(expected)
      end
    end

    context '#attributes_with_association_names' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        group_access_instance.group_ids_access_map = expected

        result = group_access_instance.attributes_with_association_names
        expect(result['group_ids']).to eq(expected)
      end

      it 'includes groups as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        group_access_instance.group_names_access_map = expected

        result = group_access_instance.attributes_with_association_names
        expect(result['groups']).to eq(expected)
      end
    end

    context '.group_access' do

      it 'responds to group_access' do
        expect(described_class).to respond_to(:group_access)
      end

      before(:each) do
        group_access_instance.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'lists only active instances' do
        group_access_instance_inactive.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(group_access_instance_inactive)
      end

      context 'Group ID parameter' do
        include_examples '.group_access call' do
          let(:group_parameter) { group_read.id }
        end
      end

      context 'Group parameter' do
        include_examples '.group_access call' do
          let(:group_parameter) { group_read }
        end
      end
    end

    context '.group_access_ids' do

      it 'responds to group_access_ids' do
        expect(described_class).to respond_to(:group_access_ids)
      end

      it 'wraps .group_access' do
        expect(described_class).to receive(:group_access).and_call_original
        described_class.group_access_ids(group_read, 'read')
      end

      it 'returns class instances' do
        group_access_instance.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access_ids(group_read, 'read')
        expect(result).to include(group_access_instance.id)
      end
    end

    it 'destroys relations before instance gets destroyed' do

      group_access_instance.group_names_access_map = {
        group_full.name     => 'full',
        group_read.name     => 'read',
        group_inactive.name => 'change',
      }
      expect do
        group_access_instance.destroy
      end.to change {
        described_class.group_through.klass.count
      }.by(-3)
    end
  end
end

RSpec.shared_examples '#group_access? call' do
  context 'single access' do

    it 'checks positive' do
      expect(group_access_instance.group_access?(group_parameter, 'read')).to be true
    end

    it 'checks negative' do
      expect(group_access_instance.group_access?(group_parameter, 'change')).to be false
    end
  end

  context 'access list' do

    it 'checks positive' do
      expect(group_access_instance.group_access?(group_parameter, %w[read change])).to be true
    end

    it 'checks negative' do
      expect(group_access_instance.group_access?(group_parameter, %w[change create])).to be false
    end
  end
end

RSpec.shared_examples '.group_access call' do
  context 'single access' do

    it 'lists access IDs' do
      expect(described_class.group_access(group_parameter, 'read')).to include(group_access_instance)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access(group_parameter, 'change')).not_to include(group_access_instance)
    end
  end

  context 'access list' do

    it 'lists access IDs' do
      expect(described_class.group_access(group_parameter, %w[read change])).to include(group_access_instance)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access(group_parameter, %w[change create])).not_to include(group_access_instance)
    end
  end
end
