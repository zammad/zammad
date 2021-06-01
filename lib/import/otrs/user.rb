# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class User
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime:    :updated_at,
        CreateTime:    :created_at,
        CreateBy:      :created_by_id,
        ChangeBy:      :updated_by_id,
        UserID:        :id,
        Comment:       :note,
        UserEmail:     :email,
        UserFirstname: :firstname,
        UserLastname:  :lastname,
        UserLogin:     :login,
      }.freeze

      def initialize(user)
        import(user)
      end

      private

      def import(user)
        create_or_update(map(user))
      end

      def create_or_update(user)
        ensure_unique_login(user)
        return if updated?(user)

        create(user)
      end

      def updated?(user)
        @local_user = ::User.find_by(id: user[:id])
        return false if !@local_user

        # only update roles if different (reduce sql statements)
        if user[:role_ids]&.sort == @local_user.role_ids.sort
          user.delete(:role_ids)
        end

        log "update User.find_by(id: #{user[:id]})"
        @local_user.update!(user)
        true
      end

      def create(user)
        log "add User.find_by(id: #{user[:id]})"
        @local_user    = ::User.new(user)
        @local_user.id = user[:id]
        @local_user.save
        reset_primary_key_sequence('users')
      end

      def ensure_unique_login(user)
        user[:login] = unique_login(user)
      end

      def unique_login(user)
        login = user[:login]
        return login if ::User.where('login = ? AND id != ?', login.downcase, user[:id]).count.zero?

        "#{login}_#{user[:id]}"
      end

      def map(user)
        mapped = map_default(user)
        mapped[:email].downcase!
        mapped[:login].downcase!
        mapped
      end

      def map_default(user)
        {
          created_by_id: 1,
          updated_by_id: 1,
          active:        active?(user),
          source:        'OTRS Import',
          role_ids:      role_ids(user),
          group_ids:     group_ids(user),
          password:      password(user),
        }
          .merge(from_mapping(user))
      end

      def password(user)
        return if !user['UserPw']

        "{sha2}#{user['UserPw']}"
      end

      def group_ids(user)
        result = []
        queues = Import::OTRS::Requester.load('Queue')
        queues.each do |queue|

          permissions = user['GroupIDs'][ queue['GroupID'] ]
          permissions ||= user['GroupIDs'][ queue['GroupID'].to_s ]

          next if !permissions
          next if permissions.exclude?('rw')

          result.push queue['QueueID']
        end

        # lookup by roles

        # roles of user
        #   groups of roles
        #     queues of group

        result
      end

      def role_ids(user)
        local_role_ids = []
        roles(user).each do |role|
          role_lookup = Role.lookup(name: role)
          next if !role_lookup

          local_role_ids.push role_lookup.id
        end
        local_role_ids
      end

      def roles(user)
        local_roles = ['Agent']
        local_roles += groups_from_otrs_groups(user)
        local_roles += groups_from_otrs_roles(user)
        local_roles.uniq
      end

      def groups_from_otrs_groups(role_object)
        groups = Import::OTRS::Requester.load('Group')
        groups_from_groups(role_object, groups)
      end

      def groups_from_groups(role_object, groups)
        result = []
        groups.each do |group|
          result += groups_from_otrs_group(role_object, group)
        end
        result
      end

      def groups_from_otrs_group(role_object, group)
        result = []
        return result if role_object.blank?
        return result if role_object['GroupIDs'].blank?

        permissions = role_object['GroupIDs'][ group['ID'] ]
        permissions ||= role_object['GroupIDs'][ group['ID'].to_s ]

        return result if !permissions

        if group['Name'] == 'admin' && permissions.include?('rw')
          result.push 'Admin'
        end

        return result if !group['Name'].match?(%r{^(stats|report)})
        return result if !( permissions.include?('ro') || permissions.include?('rw') )

        result.push 'Report'
        result
      end

      def groups_from_otrs_roles(user)
        result = []
        roles  = Import::OTRS::Requester.load('Role')
        roles.each do |role|
          next if user['RoleIDs'].exclude?(role['ID'])

          result += groups_from_otrs_groups(role)
        end
        result
      end
    end
  end
end
