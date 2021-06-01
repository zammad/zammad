# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    let(:admin) { create(:admin, groups: [group]) }
    let(:group) { create(:group) }
    let(:client_id) { '12345' }
    let(:ttl) { 3 } # seconds

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

      it 'is optimized to not send duplicate asset entries over all events' do
        collection_assets = collection.push.map { |hash| hash[:data][:assets] }

        # match all event assets against the assets of the other events
        # and make sure that each asset entry is unique over all events assets
        unique_asssets = collection_assets.each_with_index.all? do |lookup_assets, lookup_index|

          collection_assets.each_with_index.none? do |comparison_assets, comparison_index|

            # skip assets comparison for same event
            next if comparison_index == lookup_index

            # check that none of the lookup_assets assets is present
            # in the comparison_assets
            lookup_assets.keys.any? do |model|
              # skip Models that are only present in our lookup_assets entry
              next if !comparison_assets.key?(model)

              # check if there are no intersect Model record IDs
              # aka IDs present in both hashes
              intersection_ids = lookup_assets[model].keys & comparison_assets[model].keys
              intersection_ids.present?
            end
          end
        end

        expect(unique_asssets).to be(true)
      end

      it 'includes FE assets for all overviews and tickets not pushed in the last two hours' do

        # ATTENTION: we can't compare the arrays of assets directly
        # because the Ticket::Overviews backend contain an optimization logic that sends an asset entry only once
        # while the Sessions::Backend::* classes results contain all assets for each entry.
        # Therefore we merge all assets for each of the both arrays to have two big Hashes that contains all assets.
        # See previous example for the matching spec.

        collection_assets        = collection.push.map { |hash| hash[:data][:assets] }
        collection_assets_merged = collection_assets.each_with_object({}) { |assets, result| result.deep_merge!(assets) }

        overviews_all_assets        = Ticket::Overviews.all(current_user: admin).map { |overview| overview.assets({}) }
        overviews_all_assets_merged = overviews_all_assets.each_with_object({}) { |assets, result| result.deep_merge!(assets) }

        expect(collection_assets_merged).to eq(overviews_all_assets_merged)
      end

      context 'when called twice, with no changes to Ticket and Overview tables' do
        let!(:first_call) { collection.push }

        it 'returns nil' do
          expect(collection.push).to eq(nil)
        end

        context 'even after the TTL has passed' do
          before { travel(ttl + 1) }

          it 'returns nil' do
            expect(collection.push).to eq(nil)
          end
        end

        context 'even after .reset with the user’s id' do
          before { described_class.reset(admin.id) }

          it 'returns nil' do
            expect(collection.push).to eq(nil)
          end
        end
      end

      context 'when called twice, after changes have occurred to the Ticket table' do
        let!(:ticket) { create(:ticket, group: group) }
        let!(:first_call) { collection.push }

        context 'before the TTL has passed' do
          it 'returns nil' do
            expect(collection.push).to eq(nil)
          end

          context 'after .reset with the user’s id' do
            before { described_class.reset(admin.id) }

            it 'returns nil because no ticket and no overview has changed' do
              expect(collection.push).to eq(nil)
            end
          end
        end

        context 'after the TTL has passed' do
          before { travel(ttl + 1) }

          it 'returns an empty result' do
            expect(collection.push).to eq(nil)
          end
        end

        context 'after two hours have passed' do
          before { travel(2.hours + 1.second) }

          it 'returns an empty result' do
            expect(collection.push).to eq(nil)
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
