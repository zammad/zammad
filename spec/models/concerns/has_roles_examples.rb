RSpec.shared_examples 'HasRoles' do

  context 'role' do

    let(:factory_name) { described_class.name.downcase.to_sym }
    let(:instance) { create(factory_name) }
    let(:instance_inactive) { create(factory_name, active: false) }
    let(:role) { create(:role) }
    let(:group_instance) { create(:group) }
    let(:group_role) { create(:group) }
    let(:group_inactive) { create(:group, active: false) }

    context '#role_access?' do

      before(:each) do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        instance.roles = [role]
      end

      it 'responds to role_access?' do
        expect(instance).to respond_to(:role_access?)
      end

      context 'Group ID parameter' do
        include_examples '#role_access? call' do
          let(:group_parameter) { group_role.id }
        end
      end

      context 'Group parameter' do
        include_examples '#role_access? call' do
          let(:group_parameter) { group_role }
        end
      end

      it 'prevents inactive Group' do
        role.group_names_access_map = {
          group_inactive.name => 'read',
        }

        expect(instance.group_access?(group_inactive.id, 'read')).to be false
      end

      it 'prevents inactive Role' do
        role_inactive = create(:role, active: false)
        role_inactive.group_names_access_map = {
          group_role.name => 'read',
        }

        instance.roles = [role_inactive]

        expect(instance.group_access?(group_role.id, 'read')).to be false
      end
    end

    context '.role_access_ids' do

      before(:each) do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        instance.roles = [role]
      end

      it 'responds to role_access_ids' do
        expect(described_class).to respond_to(:role_access_ids)
      end

      it 'lists only active instance IDs' do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        result = described_class.group_access_ids(group_role.id, 'read')
        expect(result).not_to include(instance_inactive.id)
      end

      it 'lists only active instance IDs' do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        instance_inactive.roles = [role]

        result = described_class.role_access_ids(group_role.id, 'read')
        expect(result).not_to include(instance_inactive.id)
      end

      context 'Group ID parameter' do
        include_examples '.role_access_ids call' do
          let(:group_parameter) { group_role.id }
        end
      end

      context 'Group parameter' do
        include_examples '.role_access_ids call' do
          let(:group_parameter) { group_role.id }
        end
      end
    end

    context 'group' do

      before(:each) do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        instance.roles = [role]

        instance.group_names_access_map = {
          group_instance.name => 'read',
        }
      end

      context '#group_access?' do

        it 'falls back to #role_access?' do
          expect(instance).to receive(:role_access?)
          instance.group_access?(group_role, 'read')
        end

        it "doesn't fall back to #role_access? if not needed" do
          expect(instance).not_to receive(:role_access?)
          instance.group_access?(group_instance, 'read')
        end
      end

      context '#group_ids_access' do

        before(:each) do
          role.group_names_access_map = {
            group_role.name => 'read',
          }

          instance.roles = [role]

          instance.group_names_access_map = {
            group_instance.name => 'read',
          }
        end

        it 'lists only active Group IDs' do
          role.group_names_access_map = {
            group_role.name     => 'read',
            group_inactive.name => 'read',
          }

          result = instance.group_ids_access('read')
          expect(result).not_to include(group_inactive.id)
        end

        context 'single access' do

          it 'lists access Group IDs' do
            result = instance.group_ids_access('read')
            expect(result).to include(group_role.id)
          end

          it "doesn't list for no access" do
            result = instance.group_ids_access('write')
            expect(result).not_to include(group_role.id)
          end

          it "doesn't contain duplicate IDs" do
            instance.group_names_access_map = {
              group_role.name => 'read',
            }

            result = instance.group_ids_access('read')
            expect(result.uniq).to eq(result)
          end
        end

        context 'access list' do

          it 'lists access Group IDs' do
            result = instance.group_ids_access(%w(read write))
            expect(result).to include(group_role.id)
          end

          it "doesn't list for no access" do
            result = instance.group_ids_access(%w(write create))
            expect(result).not_to include(group_role.id)
          end

          it "doesn't contain duplicate IDs" do
            instance.group_names_access_map = {
              group_role.name => 'read',
            }

            result = instance.group_ids_access(%w(read create))
            expect(result.uniq).to eq(result)
          end
        end
      end

      context '.group_access_ids' do

        it 'includes the result of .role_access_ids' do
          result = described_class.group_access_ids(group_role, 'read')
          expect(result).to include(instance.id)
        end

        it "doesn't contain duplicate IDs" do
          instance.group_names_access_map = {
            group_role.name => 'read',
          }

          result = described_class.group_access_ids(group_role, 'read')
          expect(result.uniq).to eq(result)
        end
      end
    end
  end
end

RSpec.shared_examples '#role_access? call' do
  context 'single access' do

    it 'checks positive' do
      expect(instance.role_access?(group_parameter, 'read')).to be true
    end

    it 'checks negative' do
      expect(instance.role_access?(group_parameter, 'write')).to be false
    end
  end

  context 'access list' do

    it 'checks positive' do
      expect(instance.role_access?(group_parameter, %w(read write))).to be true
    end

    it 'checks negative' do
      expect(instance.role_access?(group_parameter, %w(write create))).to be false
    end
  end
end

RSpec.shared_examples '.role_access_ids call' do
  context 'single access' do

    it 'lists access IDs' do
      expect(described_class.role_access_ids(group_parameter, 'read')).to include(instance.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.role_access_ids(group_parameter, 'write')).not_to include(instance.id)
    end
  end

  context 'access list' do

    it 'lists access IDs' do
      expect(described_class.role_access_ids(group_parameter, %w(read write))).to include(instance.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.role_access_ids(group_parameter, %w(write create))).not_to include(instance.id)
    end
  end
end
