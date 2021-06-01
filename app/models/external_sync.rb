# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ExternalSync < ApplicationModel
  store :last_payload

  class << self

    def changed?(object:, current_changes:, previous_changes: {})
      changed = false
      previous_changes ||= {}
      current_changes.each do |attribute, value|
        next if !object.attributes.key?(attribute.to_s)
        next if object[attribute] == value
        next if object[attribute].present? && object[attribute] != previous_changes[attribute]

        begin
          object[attribute] = value
          changed         ||= true
        rescue => e
          Rails.logger.error "Unable to assign attribute #{attribute} to object #{object.class.name}: #{e.inspect}"
        end
      end
      changed
    end

    def map(source:, mapping: {})

      information_source = if source.is_a?(Hash)
                             source.deep_symbolize_keys
                           else
                             source.clone
                           end

      result = {}
      mapping.each do |remote_key, local_key|

        local_key_sym = local_key.to_sym

        next if result[local_key_sym].present?

        value = extract(remote_key, information_source)
        next if value.blank?

        result[local_key_sym] = value
      end
      result
    end

    def migrate(object, from_id, to_id)
      where(
        object: object,
        o_id:   from_id,
      ).update_all( # rubocop:disable Rails/SkipsModelValidations
        o_id: to_id,
      )
    end

    private

    def extract(remote_key, structure)
      return if !structure

      information_source = structure.clone
      result             = nil
      information_path   = remote_key.split('.')
      storable_classes   = %w[String Integer Float Bool Array]
      information_path.each do |segment|

        segment_sym = segment.to_sym

        if information_source.is_a?(Hash)
          value = information_source[segment_sym]
        elsif information_source.respond_to?(segment_sym)
          # prevent accessing non-attributes (e.g. destroy)
          break if information_source.respond_to?(:attributes) && !information_source.attributes.key?(segment)

          value = information_source.send(segment_sym)
        end
        break if !value

        storable = value.class.ancestors.any? do |ancestor|
          storable_classes.include?(ancestor.to_s)
        end

        if storable
          result = value
          break
        end

        information_source = value
      end
      result
    end
  end
end
