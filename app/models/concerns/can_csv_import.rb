# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'csv'

module CanCsvImport
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

  result = Model.csv_import(
    string: csv_string,
    parse_params: {
      col_sep: ',',
    },
    try: true,
    delete: false,
  )

  result = Model.csv_import(
    file: '/file/location/of/file.csv',
    parse_params: {
      col_sep: ',',
    },
    try: true,
    delete: false,
  )

  result = TextModule.csv_import(
    file: '/Users/me/Downloads/Textbausteine_final.csv',
    parse_params: {
      col_sep: ',',
    },
    try: false,
    delete: false,
  )

returns

  {
    records: [record1, ...]
    try: true, # true|false
    success: true, # true|false
  }

=end

    def csv_import(data)
      try    = data[:try].to_s == 'true'
      delete = data[:delete].to_s == 'true'

      begin
        data[:string] = File.read(data[:file]) if data[:file].present?
      rescue Errno::ENOENT
        raise Exceptions::UnprocessableEntity, "No such file '#{data[:file]}'"
      rescue => e
        raise Exceptions::UnprocessableEntity, "Unable to read file '#{data[:file]}': #{e.inspect}"
      end

      header, *rows = ::CSV.parse(data[:string], data[:parse_params])

      header&.each do |column|
        column.try(:strip!)
        column.try(:downcase!)
      end

      begin
        raise "Delete is not possible for #{self}." if delete && !csv_delete_possible
        raise "Unable to parse empty file/string for #{self}." if data[:string].blank?
        raise "Unable to parse file/string without header for #{self}." if header.blank?
        raise "No records found in file/string for #{self}." if rows.first.blank?
        raise "No lookup column like #{lookup_keys.map(&:to_s).join(',')} for #{self} found." if (header & lookup_keys.map(&:to_s)).none?
      rescue => e
        return {
          try:    try,
          result: 'failed',
          errors: [e.message],
        }
      end

      # get payload based on csv
      payload = []
      rows.each do |row|
        if row.first(2).any?(&:present?)
          payload.push(
            header.zip(row).to_h
                  .compact.transform_values(&:strip)
                  .except(nil).transform_keys(&:to_sym)
                  .except(*csv_attributes_ignored)
                  .merge(data[:fixed_params] || {})
          )
        else
          header.zip(row).to_h
                .compact.transform_values(&:strip)
                .except(nil).transform_keys(&:to_sym)
                .each { |col, val| payload.last[col] = [*payload.last[col], val] }
        end
      end

      stats = {
        created: 0,
        updated: 0,
        deleted: (count if delete),
      }.compact

      # delete
      destroy_all if delete && !try

      # create or update records
      records = []
      errors  = []

      transaction do
        payload.each.with_index do |attributes, i|
          record = (lookup_keys & attributes.keys).lazy.map do |lookup_key|
            params = attributes.slice(lookup_key)
            params.transform_values!(&:downcase) if lookup_key.in?(%i[email login])
            lookup(params)
          end.detect(&:present?)

          if record&.in?(records)
            errors.push "Line #{i.next}: duplicate record found."
            next
          end

          if !record && attributes[:id].present?
            errors.push "Line #{i.next}: unknown #{self} with id '#{attributes[:id]}'."
            next
          end

          if record&.id&.in?(csv_object_ids_ignored)
            errors.push "Line #{i.next}: unable to update #{self} with id '#{attributes[:id]}'."
            next
          end

          begin
            clean_params = association_name_to_id_convert(attributes)
          rescue => e
            errors.push "Line #{i.next}: #{e.message}"
            next
          end

          # create object
          Transaction.execute(disable_notification: true, reset_user_id: true, bulk: true) do
            UserInfo.current_user_id = clean_params[:updated_by_id] || clean_params[:created_by_id]

            if !record || delete == true
              stats[:created] += 1
              begin
                csv_verify_attributes(clean_params)

                record = new(param_cleanup(clean_params).reverse_merge(created_by_id: 1, updated_by_id: 1))
                record.associations_from_param(attributes)
                record.save!
              rescue => e
                errors.push "Line #{i.next}: Unable to create record - #{e.message}"
                next
              end
            else
              stats[:updated] += 1

              begin
                csv_verify_attributes(clean_params)
                clean_params = param_cleanup(clean_params).reverse_merge(updated_by_id: 1)

                record.with_lock do
                  record.associations_from_param(attributes)
                  record.assign_attributes(clean_params)
                  record.save! if record.changed?
                end
              rescue => e
                errors.push "Line #{i.next}: Unable to update record - #{e.message}"
                next
              end
            end
          end

          records.push record if record
        end
      ensure
        raise ActiveRecord::Rollback if try || errors.any?
      end

      {
        stats:   stats,
        records: records,
        errors:  errors,
        try:     try,
        result:  errors.empty? ? 'success' : 'failed',
      }
    end

=begin

verify if attributes are valid, will raise an ArgumentError with "unknown attribute '#{key}' for #{new.class}."

  Model.csv_verify_attributes({'attribute': 'some value'})

=end

    def csv_verify_attributes(clean_params)
      all_clean_attributes = {}
      new.attributes.each_key do |attribute|
        all_clean_attributes[attribute.to_sym] = true
      end
      reflect_on_all_associations.map do |assoc|
        all_clean_attributes[assoc.name.to_sym] = true
        ref = if assoc.name.to_s.end_with?('_id')
                "#{assoc.name}_id"
              else
                "#{assoc.name.to_s.chop}_ids"
              end
        all_clean_attributes[ref.to_sym] = true
      end
      clean_params.each_key do |key|
        next if all_clean_attributes.key?(key.to_sym)

        raise ArgumentError, "unknown attribute '#{key}' for #{new.class}."
      end
      true
    end

=begin

  csv_string = Model.csv_example(
    col_sep: ',',
  )

returns

  csv_string

=end

    def csv_example(params = {})
      header = []
      records = where.not(id: csv_object_ids_ignored).offset(1).limit(23).to_a
      if records.count < 20
        record_ids = records.pluck(:id).concat(csv_object_ids_ignored)
        local_records = where.not(id: record_ids).limit(20 - records.count)
        records.concat(local_records)
      end
      records_attributes_with_association_names = []
      records.each do |record|
        record_attributes_with_association_names = record.attributes_with_association_names
        records_attributes_with_association_names.push record_attributes_with_association_names
        record_attributes_with_association_names.each do |key, value|
          next if value.instance_of?(ActiveSupport::HashWithIndifferentAccess)
          next if value.instance_of?(Hash)
          next if csv_attributes_ignored&.include?(key.to_sym)
          next if key.end_with?('_id')
          next if key.end_with?('_ids')
          next if key == 'created_by'
          next if key == 'updated_by'
          next if key == 'created_at'
          next if key == 'updated_at'
          next if header.include?(key)

          header.push key
        end
      end

      rows = []
      records_attributes_with_association_names.each do |record|
        row = []
        rows_to_add = []
        position = -1
        header.each do |key|
          position += 1
          if record[key].instance_of?(ActiveSupport::TimeWithZone)
            row.push record[key].iso8601
            next
          end
          if record[key].instance_of?(Array)
            entry_count = -2
            record[key].each do |entry|
              entry_count += 1
              next if entry_count == -1

              if !rows_to_add[entry_count]
                rows_to_add[entry_count] = Array.new(header.count + 1) { '' }
              end
              rows_to_add[entry_count][position] = entry
            end
            record[key] = record[key][0]
          end
          row.push record[key]
        end
        rows.push row
        next if rows_to_add.count.zero?

        rows_to_add.each do |item|
          rows.push item
        end
        rows_to_add = []
      end
      ::CSV.generate(params) do |csv|
        csv << header
        rows.each do |row|
          csv << row
        end
      end
    end

=begin

serve method to ignore model based on id

class Model < ApplicationModel
  include CanCsvImport
  csv_object_ids_ignored(1, 2, 3)
end

=end

    def csv_object_ids_ignored(*object_ids)
      return @csv_object_ids_ignored || [] if object_ids.empty?

      @csv_object_ids_ignored = object_ids
    end

=begin

serve method to ignore model attributes

class Model < ApplicationModel
  include CanCsvImport
  csv_attributes_ignored :password,
    :image_source,
    :login_failed,
    :source,
    :image_source,
    :image,
    :authorizations,
    :organizations

end

=end

    def csv_attributes_ignored(*attributes)
      return @csv_attributes_ignored || [] if attributes.empty?

      @csv_attributes_ignored = attributes
    end

=begin

serve method to define if delete option is possible or not

class Model < ApplicationModel
  include CanCsvImport
  csv_delete_possible true

end

=end

    def csv_delete_possible(*value)
      return @csv_delete_possible if value.empty?

      @csv_delete_possible = value.first
    end
  end
end
