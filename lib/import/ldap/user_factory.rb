module Import
  class Ldap
    module UserFactory
      extend Import::StatisticalFactory

      def self.import(config: nil, ldap: nil, **kargs)

        # config might be an empty Hash due to the ImportJob payload
        # store column which will be an empty hash if the content is NULL
        if config.blank?
          config = Setting.get('ldap_config')
        end

        ldap ||= ::Ldap.new(config)

        @config = config
        @ldap   = ldap

        user_roles = user_roles(ldap: @ldap, config: config)

        if config[:unassigned_users].blank? || config[:unassigned_users] == 'sigup_roles'
          signup_role_ids = Role.signup_role_ids.sort
        end

        @dry_run = kargs[:dry_run]
        pre_import_hook([], config, user_roles, signup_role_ids, kargs)

        import_job       = kargs[:import_job]
        import_job_count = 0

        # limit the fetched attributes for an entry to only
        # those which are needed to improve the performance
        relevant_attributes = config[:user_attributes].keys
        relevant_attributes.push('dn')

        @found_lost_remote_ids = []
        @found_remote_ids      = []
        @ldap.search(config[:user_filter], attributes: relevant_attributes) do |entry|
          backend_instance = create_instance(entry, config, user_roles, signup_role_ids, kargs)
          post_import_hook(entry, backend_instance, config, user_roles, signup_role_ids, kargs)

          track_found_remote_ids(backend_instance)

          next if import_job.blank?
          import_job_count += 1
          next if import_job_count < 100

          import_job.result = @statistics
          import_job.save

          import_job_count = 0
        end

        handle_lost
      end

      def self.pre_import_hook(_records, *_args)
        super
        add_sum_to_statistics
      end

      def self.add_sum_to_statistics
        cache_key = "#{@ldap.host}::#{@ldap.port}::#{@ldap.ssl}::#{@ldap.base_dn}::#{@config[:user_filter]}"
        if !@dry_run
          sum = Cache.get(cache_key)
        end

        sum ||= @ldap.count(@config[:user_filter])

        @statistics[:sum] = sum

        return if !@dry_run
        Cache.write(cache_key, sum, { expires_in: 1.hour })
      end

      def self.add_to_statistics(backend_instance)
        super

        # no need to count if no resource was created
        resource = backend_instance.resource
        return if resource.blank?

        action = backend_instance.action

        add_resource_role_ids_to_statistics(resource.role_ids, action)

        action
      end

      def self.add_resource_role_ids_to_statistics(role_ids, action)
        return if role_ids.blank?

        known_actions = {
          created:     0,
          updated:     0,
          unchanged:   0,
          failed:      0,
          deactivated: 0,
        }

        @statistics[:role_ids] ||= {}

        role_ids.each do |role_id|

          next if !known_actions.key?(action)

          @statistics[:role_ids][role_id] ||= known_actions.dup

          # exit early if we have an unloggable action
          break if @statistics[:role_ids][role_id][action].nil?

          @statistics[:role_ids][role_id][action] += 1
        end
      end

      def self.user_roles(ldap:, config:)
        group_config = {
          filter: config[:group_filter]
        }

        ldap_group = ::Ldap::Group.new(group_config, ldap: ldap)
        ldap_group.user_roles(config[:group_role_map])
      end

      def self.track_found_remote_ids(backend_instance)
        remote_id = backend_instance.remote_id(nil)
        @deactivation_actions ||= %i(skipped failed)
        if @deactivation_actions.include?(backend_instance.action)
          @found_lost_remote_ids.push(remote_id)
        else
          @found_remote_ids.push(remote_id)
        end
      end

      def self.handle_lost
        backend_class = backend_class(nil)
        lost_map      = backend_class.lost_map(@found_remote_ids)

        # disabled count is tracked as a separate number
        # since they don't have to be in the sum (e.g. deleted in LDAP)
        @statistics[:deactivated] = lost_map.size

        # skipped deactivated are those who
        # were found, skipped and will get deactivated
        skipped_deactivated    = @found_lost_remote_ids & lost_map.keys
        @statistics[:skipped] -= skipped_deactivated.size

        # loop over every lost user ID and add the
        # deactivated count to the statistics
        lost_ids = lost_map.values

        lost_ids.each do |user_id|
          role_ids = ::User.joins(:roles)
                           .where(id: user_id)
                           .pluck(:'roles_users.role_id')

          add_resource_role_ids_to_statistics(role_ids, :deactivated)
        end

        # deactivate entries only on live syncs
        return if @dry_run
        backend_class.deactivate_lost(lost_ids)
      end
    end
  end
end
