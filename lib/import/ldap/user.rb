module Import
  class Ldap
    class User < Import::ModelResource

      def remote_id(_resource, *_args)
        @remote_id
      end

      private

      def import(resource, *args)
        normalized_entry = normalize_entry(resource)

        # extract the uid attribute and store it as
        # the remote ID so we can access later
        # when working with ExternalSync
        @remote_id = normalized_entry[ @ldap_config[:user_uid].to_sym ]

        super(normalized_entry, *args)
      end

      def normalize_entry(resource)
        normalized_entry = resource.to_h

        normalized_entry.each do |key, values|
          normalized_entry[key] = values.first
        end

        normalized_entry
      end

      def create_or_update(resource, *args)
        return if skip?(resource)
        result = super(resource, *args)

        ldap_log(
          action:  "#{action} -> #{@resource.login}",
          status:  'success',
          request: resource,
        )

        result
      end

      def skip?(resource)
        return true if resource[:login].blank?

        # skip resource if only ignored attributes are set
        ignored_attributes = %i(login dn created_by_id updated_by_id)
        !resource.except(*ignored_attributes).values.any?(&:present?)
      end

      def role_ids(resource)
        # remove remporary added and get value
        dn = resource.delete(:dn)
        # use signup roles if no dn is present
        return @signup_role_ids if !dn
        # check if roles are mapped for the found dn
        roles = @dn_roles[ dn.downcase ]
        # return found roles
        return roles if roles
        # return signup roles if there is a role mapping in general
        # this makes the LDAP the leading source of roles
        return @signup_role_ids if @dn_roles.present?

        # special case: there is no LDAP role mapping configured
        #
        # if there is no role mapping in general the signup roles
        # should only get used for newly created users (see .create method)
        # otherwise users might overwrite their local assigned
        # roles with less privileged roles and lock theirselfs out
        #
        # see issue 350#issuecomment-295252402
        #
        # this method only gets called from the .updated? method
        # so we won't return any roles which will keep the current
        # role assignment for the User
        # the signup roles will be taken in this case direcly in
        # the .create method
        nil
      end

      def updated?(resource, *_args)

        # this is needed for the special case described in the role_ids method
        #
        # assign roles only if there are any found in the mapping
        # otherwise keep those stored to the User
        update_roles        = role_ids(resource)
        resource[:role_ids] = update_roles if update_roles

        user_found = super

        # in case a User was found and we had no roles
        # to set/update we have to note the currently
        # assigned roles so that our action check won't
        # falsly detect changes to the User
        if user_found && update_roles.blank?
          resource[:role_ids] = @resource.role_ids
        end

        user_found
      rescue => e
        ldap_log(
          action:   "update -> #{resource[:login]}",
          status:   'failed',
          request:  resource,
          response: e.message,
        )
        raise
      end

      def lookup_existing(resource, *args)
        instance = super

        return instance if instance.present?

        # in some cases the User will get created in
        # Zammad before it's created in the LDAP
        # therefore we have to make a local lookup, too
        instance = local_lookup(resource)

        # create an external sync entry to connect
        # the LDAP and local account for future runs
        if instance.present?
          external_sync_create(
            local:  instance,
            remote: resource,
          )

          store_associations_state(instance)
        end

        instance
      end

      def local_lookup(resource, *_args)
        instance = import_class.identify(@remote_id)

        if instance.blank?
          checked_values = [@remote_id]
          %i(login email).each do |attribute|
            check_value = resource[attribute]
            next if check_value.blank?
            next if checked_values.include?(check_value)
            instance = import_class.identify(check_value)
            break if instance.present?
            checked_values.push(check_value)
          end
        end
        instance
      end

      def tracked_associations
        [:role_ids]
      end

      def create(resource, *_args)

        # this is needed for the special case described in the role_ids method
        #
        # in case we have no role IDs yet we have to fall back to the signup roles
        resource[:role_ids] ||= @signup_role_ids
        super
      rescue => e
        ldap_log(
          action:   "create -> #{resource[:login]}",
          status:   'failed',
          request:  resource,
          response: e.message,
        )
        raise
      end

      def map(_resource, *_args)
        mapped = super

        # we have to manually downcase the login and email
        # to avoid wrong attribute change detection
        %i(login email).each do |attribute|
          next if mapped[attribute].blank?
          mapped[attribute] = mapped[attribute].downcase
        end

        mapped
      end

      def mapping(*_args)
        @mapping ||= begin
          mapping = @ldap_config[:user_attributes]

          # add temporary dn to mapping so we can use it
          # for the role lookup later and delete it afterwards
          mapping['dn'] = 'dn'

          # fallback to uid if no login is given via mapping
          if !mapping.values.include?('login')
            mapping[ @ldap_config[:user_uid] ] = 'login'
          end

          mapping
        end
      end

      def handle_args(resource, *args)
        @ldap_config     = args.shift
        @dn_roles        = args.shift
        @signup_role_ids = args.shift

        super(resource, *args)
      end

      def ldap_log(action:, status:, request:, response: nil)
        return if @dry_run

        HttpLog.create(
          direction:     'out',
          facility:      'ldap',
          url:           action,
          status:        status,
          ip:            nil,
          request:       { content: request.to_json },
          response:      { message: response || status },
          method:        'tcp',
          created_by_id: 1,
          updated_by_id: 1,
        )
      end

    end
  end
end
