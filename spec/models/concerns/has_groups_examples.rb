# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'HasGroups' do |group_access_factory:|
  context 'group' do
    subject { create(group_access_factory) }

    let(:group_full) { create(:group) }
    let(:group_read) { create(:group) }
    let(:group_inactive) { create(:group, active: false) }

    describe '.group_through_identifier' do

      it 'responds to group_through_identifier' do
        expect(described_class).to respond_to(:group_through_identifier)
      end

      it 'returns a Symbol as identifier' do
        expect(described_class.group_through_identifier).to be_a(Symbol)
      end

      it 'instance responds to group_through_identifier method' do
        expect(subject).to respond_to(described_class.group_through_identifier)
      end
    end

    describe '.group_through' do

      it 'responds to group_through' do
        expect(described_class).to respond_to(:group_through)
      end

      it 'returns the Reflection instance of the has_many :through relation' do
        expect(described_class.group_through).to be_a(ActiveRecord::Reflection::HasManyReflection)
      end
    end

    describe '#groups' do

      it 'responds to groups' do
        expect(subject).to respond_to(:groups)
      end

      describe '#groups.access' do

        it 'responds to groups.access' do
          expect(subject.groups).to respond_to(:access)
        end

        context 'result' do

          before do
            subject.group_names_access_map = {
              group_full.name     => 'full',
              group_read.name     => 'read',
              group_inactive.name => 'change',
            }
          end

          it 'returns all related Groups' do
            expect(subject.groups.access.size).to eq(3)
          end

          it 'adds join table attribute(s like) access' do
            expect(subject.groups.access.first).to respond_to(:access)
          end

          it 'filters for given access parameter' do
            expect(subject.groups.access('read')).to include(group_read)
          end

          it 'filters for given access list parameter' do
            expect(subject.groups.access('read', 'change')).to include(group_read, group_inactive)
          end

          it 'always includes full access groups' do
            expect(subject.groups.access('read')).to include(group_full)
          end
        end
      end
    end

    describe '#group_access?' do

      before do
        subject.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_access?' do
        expect(subject).to respond_to(:group_access?)
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
        subject.group_names_access_map = {
          group_inactive.name => 'read',
        }

        expect(subject.group_access?(group_inactive.id, 'read')).to be false
      end

      it 'prevents inactive instances' do
        subject.update!(active: false)

        subject.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(subject.group_access?(group_read.id, 'read')).to be false
      end
    end

    describe '#group_ids_access' do

      before do
        subject.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_ids_access' do
        expect(subject).to respond_to(:group_ids_access)
      end

      it 'lists only active Group IDs' do
        subject.group_names_access_map = {
          group_read.name     => 'read',
          group_inactive.name => 'read',
        }

        result = subject.group_ids_access('read')
        expect(result).not_to include(group_inactive.id)
      end

      it "doesn't list for inactive instances" do
        subject.update!(active: false)

        subject.group_names_access_map = {
          group_read.name => 'read',
        }

        expect(subject.group_ids_access('read')).to be_empty
      end

      context 'single access' do

        it 'lists access Group IDs' do
          result = subject.group_ids_access('read')
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = subject.group_ids_access('change')
          expect(result).not_to include(group_read.id)
        end
      end

      context 'access list' do

        it 'lists access Group IDs' do
          result = subject.group_ids_access(%w[read change])
          expect(result).to include(group_read.id)
        end

        it "doesn't list for no access" do
          result = subject.group_ids_access(%w[change create])
          expect(result).not_to include(group_read.id)
        end
      end
    end

    describe '#groups_access' do

      it 'responds to groups_access' do
        expect(subject).to respond_to(:groups_access)
      end

      it 'wraps #group_ids_access' do
        expect(subject).to receive(:group_ids_access)
        subject.groups_access('read')
      end

      it 'returns Groups' do
        subject.group_names_access_map = {
          group_read.name => 'read',
        }
        result = subject.groups_access('read')
        expect(result).to include(group_read)
      end
    end

    describe '#group_names_access_map=' do

      it 'responds to group_names_access_map=' do
        expect(subject).to respond_to(:group_names_access_map=)
      end

      context 'existing instance' do

        it 'stores Hash with String values' do
          expect do
            subject.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with Array<String> values' do
          expect do
            subject.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => %w[read change],
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        it 'allows empty Hash value' do
          subject.group_names_access_map = {
            group_full.name => 'full',
            group_read.name => %w[read change],
          }

          expect do
            subject.group_names_access_map = {}
          end.to change {
            described_class.group_through.klass.count
          }.by(-3)
        end

        it 'prevents having full and other privilege at the same time' do

          invalid_combination = %w[full read change]
          exception           = ActiveRecord::RecordInvalid

          expect do
            subject.group_names_access_map = {
              group_full.name => invalid_combination,
            }
          end.to raise_error(exception)

          expect do
            subject.group_names_access_map = {
              group_full.name => invalid_combination.reverse,
            }
          end.to raise_error(exception)
        end
      end

      context 'new instance' do
        subject { build(group_access_factory) }

        it "doesn't store directly" do
          expect do
            subject.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }
          end.not_to change {
            described_class.group_through.klass.count
          }
        end

        it 'stores after save' do
          expect do
            subject.group_names_access_map = {
              group_full.name => 'full',
              group_read.name => 'read',
            }

            subject.save
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'allows empty Hash value' do
          expect do
            subject.group_names_access_map = {}

            subject.save
          end.not_to change {
            described_class.group_through.klass.count
          }
        end
      end
    end

    describe '#group_names_access_map' do

      it 'responds to group_names_access_map' do
        expect(subject).to respond_to(:group_names_access_map)
      end

      it 'returns instance Group name => access relations as Hash' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        subject.group_names_access_map = expected

        expect(subject.group_names_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        subject.update!(active: false)

        subject.group_names_access_map = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        expect(subject.group_names_access_map).to be_empty
      end

      it 'returns empty map if none is stored' do

        subject.group_names_access_map = {
          group_full.name => 'full',
          group_read.name => 'read',
        }

        subject.group_names_access_map = {}

        expect(subject.group_names_access_map).to be_blank
      end
    end

    describe '#group_ids_access_map=' do

      it 'responds to group_ids_access_map=' do
        expect(subject).to respond_to(:group_ids_access_map=)
      end

      context 'existing instance' do

        it 'stores Hash with String values' do
          expect do
            subject.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'stores Hash with Array<String> values' do
          expect do
            subject.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => %w[read change],
            }
          end.to change {
            described_class.group_through.klass.count
          }.by(3)
        end

        it 'allows empty Hash value' do
          subject.group_ids_access_map = {
            group_full.id => 'full',
            group_read.id => %w[read change],
          }

          expect do
            subject.group_ids_access_map = {}
          end.to change {
            described_class.group_through.klass.count
          }.by(-3)
        end
      end

      context 'new instance' do
        subject { build(group_access_factory) }

        it "doesn't store directly" do
          expect do
            subject.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }
          end.not_to change {
            described_class.group_through.klass.count
          }
        end

        it 'stores after save' do
          expect do
            subject.group_ids_access_map = {
              group_full.id => 'full',
              group_read.id => 'read',
            }

            subject.save
          end.to change {
            described_class.group_through.klass.count
          }.by(2)
        end

        it 'allows empty Hash value' do
          expect do
            subject.group_ids_access_map = {}

            subject.save
          end.not_to change {
            described_class.group_through.klass.count
          }
        end
      end
    end

    describe '#group_ids_access_map' do

      it 'responds to group_ids_access_map' do
        expect(subject).to respond_to(:group_ids_access_map)
      end

      it 'returns instance Group ID => access relations as Hash' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        subject.group_ids_access_map = expected

        expect(subject.group_ids_access_map).to eq(expected)
      end

      it "doesn't map for inactive instances" do
        subject.update!(active: false)

        subject.group_ids_access_map = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        expect(subject.group_ids_access_map).to be_empty
      end

      it 'returns empty map if none is stored' do

        subject.group_ids_access_map = {
          group_full.id => 'full',
          group_read.id => 'read',
        }

        subject.group_ids_access_map = {}

        expect(subject.group_ids_access_map).to be_blank
      end
    end

    describe '#associations_from_param' do

      it 'handles group_ids parameter as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        subject.associations_from_param(group_ids: expected)
        expect(subject.group_ids_access_map).to eq(expected)
      end

      it 'handles groups parameter as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        subject.associations_from_param(groups: expected)
        expect(subject.group_names_access_map).to eq(expected)
      end
    end

    describe '#attributes_with_association_ids' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        subject.group_ids_access_map = expected

        result = subject.attributes_with_association_ids
        expect(result['group_ids']).to eq(expected)
      end
    end

    describe '#attributes_with_association_names' do

      it 'includes group_ids as group_ids_access_map' do
        expected = {
          group_full.id => ['full'],
          group_read.id => ['read'],
        }

        subject.group_ids_access_map = expected

        result = subject.attributes_with_association_names
        expect(result['group_ids']).to eq(expected)
      end

      it 'includes groups as group_names_access_map' do
        expected = {
          group_full.name => ['full'],
          group_read.name => ['read'],
        }

        subject.group_names_access_map = expected

        result = subject.attributes_with_association_names
        expect(result['groups']).to eq(expected)
      end
    end

    describe '.group_access' do

      before do
        subject.group_names_access_map = {
          group_read.name => 'read',
        }
      end

      it 'responds to group_access' do
        expect(described_class).to respond_to(:group_access)
      end

      it 'lists only active instances' do
        subject.update!(active: false)

        subject.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access(group_read.id, 'read')
        expect(result).not_to include(subject)
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

    describe '.group_access_ids' do

      it 'responds to group_access_ids' do
        expect(described_class).to respond_to(:group_access_ids)
      end

      it 'wraps .group_access' do
        expect(described_class).to receive(:group_access).and_call_original
        described_class.group_access_ids(group_read, 'read')
      end

      it 'returns class instances' do
        subject.group_names_access_map = {
          group_read.name => 'read',
        }

        result = described_class.group_access_ids(group_read, 'read')
        expect(result).to include(subject.id)
      end
    end

    it 'destroys relations before instance gets destroyed' do

      subject.group_names_access_map = {
        group_full.name     => 'full',
        group_read.name     => 'read',
        group_inactive.name => 'change',
      }
      expect do
        subject.destroy
      end.to change {
        described_class.group_through.klass.count
      }.by(-3)
    end
  end
end

RSpec.shared_examples '#group_access? call' do
  context 'single access' do

    it 'checks positive' do
      expect(subject.group_access?(group_parameter, 'read')).to be true
    end

    it 'checks negative' do
      expect(subject.group_access?(group_parameter, 'change')).to be false
    end
  end

  context 'access list' do

    it 'checks positive' do
      expect(subject.group_access?(group_parameter, %w[read change])).to be true
    end

    it 'checks negative' do
      expect(subject.group_access?(group_parameter, %w[change create])).to be false
    end
  end
end

RSpec.shared_examples '.group_access call' do
  context 'single access' do

    it 'lists access IDs' do
      expect(described_class.group_access(group_parameter, 'read')).to include(subject)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access(group_parameter, 'change')).not_to include(subject)
    end
  end

  context 'access list' do

    it 'lists access IDs' do
      expect(described_class.group_access(group_parameter, %w[read change])).to include(subject)
    end

    it 'excludes non access IDs' do
      expect(described_class.group_access(group_parameter, %w[change create])).not_to include(subject)
    end
  end
end
