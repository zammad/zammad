# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue1977RemoveInvalidUserForeignKeys, type: :db_migration do

  context 'no online_notifications foreign key' do

    let(:existing_user_id) { User.first.id }

    context 'invalid User foreign key columns' do

      it 'cleans up OnlineNotification#user_id', db_strategy: :reset do
        without_foreign_key(:online_notifications, column: :user_id)

        create(:online_notification, user_id: 1337)
        create(:online_notification, user_id: existing_user_id)

        expect do
          migrate
        end.to change(OnlineNotification, :count).by(-1)
      end

      it 'cleans up RecentView#created_by_id', db_strategy: :reset do
        without_foreign_key(:online_notifications, column: :user_id)
        without_foreign_key(:recent_views, column: :created_by_id)

        record = build(:recent_view, created_by_id: 1337)
        record.save(validate: false)
        create(:recent_view, created_by_id: existing_user_id)

        expect do
          migrate
        end.to change(RecentView, :count).by(-1)
      end

      it 'cleans up Avatar#o_id', db_strategy: :reset do
        without_foreign_key(:online_notifications, column: :user_id)

        create(:avatar, object_lookup_id: ObjectLookup.by_name('User'), o_id: 1337)
        create(:avatar, object_lookup_id: ObjectLookup.by_name('Ticket'), o_id: 1337)
        create(:avatar, object_lookup_id: ObjectLookup.by_name('User'), o_id: existing_user_id)

        expect do
          migrate
        end.to change(Avatar, :count).by(-1)
      end

    end

    it 'adds OnlineNotification#user_id foreign key' do
      adds_foreign_key(:online_notifications, column: :user_id)
    end
  end

end
