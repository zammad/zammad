# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Enrichment
  module Clearbit
    class Organization

      def initialize(user:, payload:)
        @user    = user
        @payload = payload
        @source  = 'clearbit'
        @config  = Setting.get('clearbit_config')
        @object  = 'Organization'
      end

      def synced?
        return false if !@config

        UserInfo.current_user_id = 1

        return false if !mapping?
        return false if !changes?

        # create new organization
        return organization_created? if !remote_id? || !external_found?

        # update existing organization
        organization = existing_organization

        return true if @user.organization_id

        # assign new organization to user
        update_user(organization)
      end

      private

      def mapping?
        @mapping = @config['organization_sync'].dup
        return false if @mapping.blank?

        # TODO: Refactoring:
        # Currently all target keys are prefixed with
        # organization.
        # which is not necessary since the target object
        # is always an organization
        @mapping.transform_values! { |value| value.sub('organization.', '') }
        true
      end

      def changes?
        @current_changes = ExternalSync.map(
          mapping: @mapping,
          source:  @payload
        )
        @current_changes.present?
      end

      def remote_id?
        return if !@payload['company']

        @remote_id = @payload['company']['id']
      end

      def external_found?
        return true if @external_organization

        @external_organization = ExternalSync.find_by(
          source:    @source,
          source_id: @remote_id,
          object:    @object,
        )
        @external_organization.present?
      end

      def organization_created?

        # if organization is already assigned, do not create a new one
        return false if @user.organization_id

        # can't create organization without name
        return false if @current_changes[:name].blank?

        organization = create_current

        # assign new organization to user
        update_user(organization)
      end

      def create_current
        organization = ::Organization.find_by(name: @current_changes[:name])

        return organization if organization

        organization = ::Organization.new(
          shared: @config['organization_shared'],
        )

        return organization if !ExternalSync.changed?(
          object:          organization,
          current_changes: @current_changes,
        )

        organization.save!

        ExternalSync.create(
          source:       @source,
          source_id:    @remote_id,
          object:       @object,
          o_id:         organization.id,
          last_payload: @payload,
        )
        organization
      end

      def load_previous_changes
        last_payload = @external_organization.last_payload
        return if !last_payload

        @previous_changes = ExternalSync.map(
          mapping: @mapping,
          source:  last_payload
        )
      end

      def existing_organization
        load_previous_changes

        organization = ::Organization.find(@external_organization[:o_id])
        return organization if !ExternalSync.changed?(
          object:           organization,
          previous_changes: @previous_changes,
          current_changes:  @current_changes,
        )

        organization.updated_by_id = 1
        organization.save!

        @external_organization.last_payload = @payload
        @external_organization.save!

        organization
      end

      def update_user(organization)
        @user.organization_id = organization.id
        true
      end
    end
  end
end
