# Rails autoload has some issues with same namend sub-classes
# in the importer folder require AND simultaniuos requiring
# of the same file in different threads so we need to
# require them ourself
require 'import/zendesk/user/group'
require 'import/zendesk/user/role'

# https://developer.zendesk.com/rest_api/docs/core/users
module Import
  module Zendesk
    class User
      include Import::Zendesk::Helper

      attr_reader :zendesk_id, :id

      def initialize(user)
        local_user  = ::User.create_or_update( local_user_fields(user) )
        @zendesk_id = user.id
        @id         = local_user.id
      end

      private

      def local_user_fields(user)
        {
          login:           login(user),
          firstname:       user.name,
          email:           user.email,
          phone:           user.phone,
          password:        password(user),
          active:          !user.suspended,
          groups:          Import::Zendesk::User::Group.for(user),
          roles:           roles(user),
          note:            user.notes,
          verified:        user.verified,
          organization_id: Import::Zendesk::OrganizationFactory.local_id( user.organization_id ),
          last_login:      user.last_login_at,
          image_source:    photo(user),
          updated_by_id:   1,
          created_by_id:   1
        }.merge(custom_fields(user))
      end

      def login(user)
        return user.email if user.email
        # Zendesk users may have no other identifier than the ID, e.g. twitter users
        user.id.to_s
      end

      def password(user)
        return Setting.get('import_zendesk_endpoint_key') if import_user?(user)
        ''
      end

      def roles(user)
        return Import::Zendesk::User::Role.map(user, 'admin') if import_user?(user)
        Import::Zendesk::User::Role.for(user)
      end

      def import_user?(user)
        return false if user.email.blank?
        user.email == Setting.get('import_zendesk_endpoint_username')
      end

      def photo(user)
        return if !user.photo
        user.photo.content_url
      end

      def custom_fields(user)
        get_fields(user.user_fields)
      end
    end
  end
end
