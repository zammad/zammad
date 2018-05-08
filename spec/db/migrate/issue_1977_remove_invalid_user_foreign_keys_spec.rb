require 'rails_helper'

RSpec.describe Issue1977RemoveInvalidUserForeignKeys, type: :db_migration do

  context 'no online_notifications foreign key' do
    self.use_transactional_tests = false

    let(:existing_user_id) { User.first.id }

    context 'invalid User foreign key columns' do

      it 'cleans up OnlineNotification#user_id' do
        witout_foreign_key(:online_notifications, column: :user_id)

        create(:online_notification, user_id: 1337)
        valid = create(:online_notification, user_id: existing_user_id)

        expect do
          migrate
        end.to change {
          OnlineNotification.count
        }.by(-1)

        # cleanup since we disabled
        # transactions for this tests
        valid.destroy
      end

      it 'cleans up RecentView#created_by_id' do
        witout_foreign_key(:online_notifications, column: :user_id)
        witout_foreign_key(:recent_views, column: :created_by_id)

        create(:recent_view, created_by_id: 1337)
        valid = create(:recent_view, created_by_id: existing_user_id)

        expect do
          migrate
        end.to change {
          RecentView.count
        }.by(-1)

        # cleanup since we disabled
        # transactions for this tests
        valid.destroy
      end

      it 'cleans up Avatar#o_id' do
        witout_foreign_key(:online_notifications, column: :user_id)

        create(:avatar, object_lookup_id: ObjectLookup.by_name('User'), o_id: 1337)
        valid_ticket = create(:avatar, object_lookup_id: ObjectLookup.by_name('Ticket'), o_id: 1337)
        valid_user   = create(:avatar, object_lookup_id: ObjectLookup.by_name('User'), o_id: existing_user_id)

        expect do
          migrate
        end.to change {
          Avatar.count
        }.by(-1)

        # cleanup since we disabled
        # transactions for this tests
        valid_ticket.destroy
        valid_user.destroy
      end

    end

    it 'adds OnlineNotification#user_id foreign key' do
      adds_foreign_key(:online_notifications, column: :user_id)
    end
  end

end
