require 'rails_helper'

RSpec.describe Sessions::Backend::TicketOverviewList do
  it 'inherits #asset_needed? from Sessions::Backend::Base' do
    expect(described_class.instance_method(:asset_needed?).owner)
      .to be(described_class.superclass)
  end

  it 'inherits #asset_push from Sessions::Backend::Base' do
    expect(described_class.instance_method(:asset_push).owner)
      .to be(described_class.superclass)
  end

  describe '.push' do
    let(:admin) { create(:admin_user, groups: [group]) }
    let(:group) { create(:group) }
    let(:client_id) { '12345' }
    let(:ttl) { 3 }  # seconds

    context 'when 3rd argument ("client") is false' do
      subject(:collection) { described_class.new(admin, {}, false, client_id, ttl) }

      it 'returns an array of hashes with :event and :data keys' do
        expect(collection.push)
          .to be_an(Array)
          .and have_attributes(length: Ticket::Overviews.all(current_user: admin).count)
          .and all(match({ event: 'ticket_overview_list', data: hash_including(:assets) }))
      end

      it 'returns one hash for each of the user’s ticket overviews' do
        expect(collection.push.map { |hash| hash[:data][:overview][:name] })
          .to match_array(Ticket::Overviews.all(current_user: admin).map(&:name))
      end

      it 'includes FE assets for all overviews and tickets not pushed in the last two hours' do
        expect(collection.push.map { |hash| hash[:data][:assets] })
          .to match_array(Ticket::Overviews.all(current_user: admin).map { |overview| overview.assets({}) })
      end

      context 'when called twice, with no changes to Ticket and Overview tables' do
        let!(:first_call) { collection.push }

        it 'returns nil' do
          expect(collection.push).to be(nil)
        end

        context 'even after the TTL has passed' do
          before { travel(ttl + 1) }

          it 'returns nil' do
            expect(collection.push).to be(nil)
          end
        end

        context 'even after .reset with the user’s id' do
          before { described_class.reset(admin.id) }

          it 'returns nil' do
            expect(collection.push).to be(nil)
          end
        end
      end

      context 'when called twice, after changes have occurred to the Ticket table' do
        let!(:ticket) { create(:ticket, group: group) }
        let!(:first_call) { collection.push }

        context 'before the TTL has passed' do
          it 'returns nil' do
            expect(collection.push).to be(nil)
          end

          context 'after .reset with the user’s id' do
            before { described_class.reset(admin.id) }

            it 'returns nil because no ticket and no overview has changed' do
              expect(collection.push).to be nil
            end
          end
        end

        context 'after the TTL has passed' do
          before { travel(ttl + 1) }

          it 'returns an empty result' do
            expect(collection.push).to eq nil
          end
        end

        context 'after two hours have passed' do
          before { travel(2.hours + 1.second) }

          it 'returns an empty result' do
            expect(collection.push).to eq nil
          end
        end
      end

      context 'when called twice, after changes have occurred to the Overviews table' do
        let!(:first_call) { collection.push }

        before { Overview.first.touch }

        context 'before the TTL has passed' do
          it 'returns nil' do
            expect(collection.push).to be(nil)
          end

          context 'after .reset with the user’s id' do
            before { described_class.reset(admin.id) }

            it 'returns an updated set of results' do
              expect(collection.push)
                .to be_an(Array)
                .and have_attributes(length: 1)
                .and all(match({ event: 'ticket_overview_list', data: hash_including(:assets) }))
            end
          end
        end

        context 'after two hours have passed' do
          before { travel(2.hours + 1.second) }

          it 'returns an empty result' do
            expect(collection.push)
              .to be_an(Array)
              .and have_attributes(length: 1)
              .and all(match({ event: 'ticket_overview_list', data: hash_including(:assets) }))
          end
        end
      end
    end
  end
end
