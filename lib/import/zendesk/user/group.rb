# this require is required (hehe) because of Rails autoloading
# which causes strange behavior not inheriting correctly
# from Import::OTRS::DynamicField
require 'import/zendesk/user'

# https://developer.zendesk.com/rest_api/docs/core/groups
module Import
  module Zendesk
    class User
      module Group

        # rubocop:disable Style/ModuleFunction
        extend self

        def for(user)
          groups = []
          return groups if mapping[user.id].empty?

          mapping[user.id].each { |zendesk_group_id|

            local_group_id = Import::Zendesk::GroupFactory.local_id(zendesk_group_id)

            next if !local_group_id

            group = ::Group.find( local_group_id )

            groups.push(group)
          }
          groups
        end

        private

        def mapping

          return @mapping if !@mapping.nil?

          @mapping = {}

          Import::Zendesk::Requester.client.group_memberships.all! { |group_membership|

            @mapping[ group_membership.user_id ] ||= []
            @mapping[ group_membership.user_id ].push( group_membership.group_id )
          }

          @mapping
        end
      end
    end
  end
end
