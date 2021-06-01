# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Enrichment
  module Clearbit
    class User

      def initialize(user)
        @local_user = user
        @source     = 'clearbit'
        @config     = Setting.get('clearbit_config')
      end

      def synced?
        return false if !@config
        return false if @local_user.email.blank?

        UserInfo.current_user_id = 1

        return false if !mapping?

        payload = fetch
        return false if !payload

        attributes_changed = attributes_changed?(payload)

        organization_synced = false
        if payload['company'] && @config['organization_autocreate']
          organization = Enrichment::Clearbit::Organization.new(
            user:    @local_user,
            payload: payload
          )
          organization_synced = organization.synced?
        end

        return false if !attributes_changed && !organization_synced

        @local_user.save if attributes_changed || organization_synced
        true
      end

      private

      def mapping?
        @mapping = @config['user_sync'].dup
        return false if @mapping.blank?

        # TODO: Refactoring:
        # Currently all target keys are prefixed with
        # user.
        # which is not necessary since the target object
        # is always a user
        @mapping.transform_values! { |value| value.sub('user.', '') }
        true
      end

      def load_remote(data)
        return if !remote_id?(data)
        return if !external_found?

        load_previous_changes
      end

      def remote_id?(data)
        return if !data
        return if !data['person']

        @remote_id = data['person']['id']
      end

      def external_found?
        return true if @external_user

        @external_user = ExternalSync.find_by(
          source:    @source,
          source_id: @remote_id,
          object:    @local_user.class.name,
          o_id:      @local_user.id,
        )
        @external_user.present?
      end

      def load_previous_changes
        last_payload = @external_user.last_payload
        return if !last_payload

        @previous_changes = ExternalSync.map(
          mapping: @mapping,
          source:  last_payload
        )
      end

      def attributes_changed?(payload)
        current_changes = ExternalSync.map(
          mapping: @mapping,
          source:  payload
        )

        return false if !current_changes

        previous_changes = load_remote(payload)

        return false if !ExternalSync.changed?(
          object:           @local_user,
          previous_changes: previous_changes,
          current_changes:  current_changes,
        )

        @local_user.updated_by_id = 1
        return true if !@remote_id

        store_current(payload)
        true
      end

      def store_current(payload)
        if !external_found?
          @external_user = ExternalSync.new(
            source:    @source,
            source_id: @remote_id,
            object:    @local_user.class.name,
            o_id:      @local_user.id,
          )
        end
        @external_user.last_payload = payload
        @external_user.save
      end

      def fetch
        if !Rails.env.production?
          filename = Rails.root.join('test', 'data', 'clearbit', "#{@local_user.email}.json")
          if File.exist?(filename)
            data = File.binread(filename)
            return JSON.parse(data) if data
          end
        end

        return if @config['api_key'].blank?

        record = {
          direction: 'out',
          facility:  'clearbit',
          url:       "clearbit -> #{@local_user.email}",
          status:    200,
          ip:        nil,
          request:   { content: @local_user.email },
          response:  {},
          method:    'GET',
        }

        begin
          ::Clearbit.key = @config['api_key']
          result = ::Clearbit::Enrichment.find(email: @local_user.email, stream: true)
          record[:response] = { code: 200, content: result.to_s }
        rescue => e
          record[:status] = 500
          record[:response] = { code: 500, content: e.inspect }
        end
        HttpLog.create(record)
        result
      end

      class << self

        def all
          users = User.of_role(Role.signup_roles)
          users.each do |user|
            new(user).synced?
          end
        end
      end
    end
  end
end
