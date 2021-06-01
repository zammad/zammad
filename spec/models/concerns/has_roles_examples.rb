# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasRoles' do |group_access_factory:|
  context 'role' do
    subject { create(group_access_factory) }

    let(:role) { create(:role) }
    let(:group_instance) { create(:group) }
    let(:group_role) { create(:group) }
    let(:group_inactive) { create(:group, active: false) }

    describe '#role_access?' do

      it 'responds to role_access?' do
        expect(subject).to respond_to(:role_access?)
      end

      context 'active Role' do
        before do
          role.group_names_access_map = {
            group_role.name => 'read',
          }

          subject.roles.push(role)
          subject.save
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

          expect(subject.group_access?(group_inactive.id, 'read')).to be false
        end
      end

      it 'prevents inactive Role' do
        role_inactive = create(:role, active: false)
        role_inactive.group_names_access_map = {
          group_role.name => 'read',
        }

        subject.roles.push(role_inactive)
        subject.save

        expect(subject.group_access?(group_role.id, 'read')).to be false
      end
    end

    describe '.role_access_ids' do

      before do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        subject.roles.push(role)
        subject.save
      end

      it 'responds to role_access_ids' do
        expect(described_class).to respond_to(:role_access_ids)
      end

      it 'lists only active instance IDs' do
        subject.update!(active: false)

        role.group_names_access_map = {
          group_role.name => 'read',
        }

        subject.roles.push(role)
        subject.save
        subject.save

        result = described_class.role_access_ids(group_role.id, 'read')
        expect(result).not_to include(subject.id)
      end

      context 'Group ID parameter' do
        include_examples '.role_access_ids call' do
          let(:group_parameter) { group_role.id }
        end
      end

      context 'Group parameter' do
        include_examples '.role_access_ids call' do
          let(:group_parameter) { group_role }
        end
      end
    end

    context 'group' do

      before do
        role.group_names_access_map = {
          group_role.name => 'read',
        }

        subject.roles.push(role)
        subject.save

        subject.group_names_access_map = {
          group_instance.name => 'read',
        }
      end

      describe '#group_access?' do

        it 'falls back to #role_access?' do
          expect(subject).to receive(:role_access?)
          subject.group_access?(group_role, 'read')
        end

        it "doesn't fall back to #role_access? if not needed" do
          expect(subject).not_to receive(:role_access?)
          subject.group_access?(group_instance, 'read')
        end
      end

      describe '#group_ids_access' do

        before do
          role.group_names_access_map = {
            group_role.name => 'read',
          }

          subject.roles.push(role)
          subject.save

          subject.group_names_access_map = {
            group_instance.name => 'read',
          }
        end

        it 'lists only active Group IDs' do
          role.group_names_access_map = {
            group_role.name     => 'read',
            group_inactive.name => 'read',
          }

          result = subject.group_ids_access('read')
          expect(result).not_to include(group_inactive.id)
        end

        context 'single access' do

          it 'lists access Group IDs' do
            result = subject.group_ids_access('read')
            expect(result).to include(group_role.id)
          end

          it "doesn't list for no access" do
            result = subject.group_ids_access('change')
            expect(result).not_to include(group_role.id)
          end

          it "doesn't contain duplicate IDs" do
            subject.group_names_access_map = {
              group_role.name => 'read',
            }

            result = subject.group_ids_access('read')
            expect(result.uniq).to eq(result)
          end
        end

        context 'access list' do

          it 'lists access Group IDs' do
            result = subject.group_ids_access(%w[read change])
            expect(result).to include(group_role.id)
          end

          it "doesn't list for no access" do
            result = subject.group_ids_access(%w[change create])
            expect(result).not_to include(group_role.id)
          end

          it "doesn't contain duplicate IDs" do
            subject.group_names_access_map = {
              group_role.name => 'read',
            }

            result = subject.group_ids_access(%w[read create])
            expect(result.uniq).to eq(result)
          end
        end
      end

      describe '.group_access_ids' do

        it 'includes the result of .role_access_ids' do
          result = described_class.group_access_ids(group_role, 'read')
          expect(result).to include(subject.id)
        end

        it "doesn't contain duplicate IDs" do
          subject.group_names_access_map = {
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
      expect(subject.role_access?(group_parameter, 'read')).to be true
    end

    it 'checks negative' do
      expect(subject.role_access?(group_parameter, 'change')).to be false
    end
  end

  context 'access list' do

    it 'checks positive' do
      expect(subject.role_access?(group_parameter, %w[read change])).to be true
    end

    it 'checks negative' do
      expect(subject.role_access?(group_parameter, %w[change create])).to be false
    end
  end
end

RSpec.shared_examples '.role_access_ids call' do
  context 'single access' do

    it 'lists access IDs' do
      expect(described_class.role_access_ids(group_parameter, 'read')).to include(subject.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.role_access_ids(group_parameter, 'change')).not_to include(subject.id)
    end
  end

  context 'access list' do

    it 'lists access IDs' do
      expect(described_class.role_access_ids(group_parameter, %w[read change])).to include(subject.id)
    end

    it 'excludes non access IDs' do
      expect(described_class.role_access_ids(group_parameter, %w[change create])).not_to include(subject.id)
    end
  end
end
