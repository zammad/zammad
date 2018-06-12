# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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
      try = true
      if data[:try] != 'true' && data[:try] != true
        try = false
      end
      delete = false
      if data[:delete] == true || data[:delete] == 'true'
        delete = true
      end

      errors = []
      if delete == true && @csv_delete_possible != true
        errors.push "Delete is not possible for #{new.class}."
        result = {
          errors: errors,
          try: try,
          result: 'failed',
        }
        return result
      end

      if data[:file].present?
        raise Exceptions::UnprocessableEntity, "No such file '#{data[:file]}'" if !File.exist?(data[:file])
        begin
          file = File.open(data[:file], 'r:UTF-8')
          data[:string] = file.read
        rescue => e
          raise Exceptions::UnprocessableEntity, "Unable to read file '#{data[:file]}': #{e.inspect}"
        end
      end
      if data[:string].blank?
        errors.push "Unable to parse empty file/string for #{new.class}."
        result = {
          errors: errors,
          try: try,
          result: 'failed',
        }
        return result
      end

      rows = ::CSV.parse(data[:string], data[:parse_params])
      header = rows.shift
      if header.blank?
        errors.push "Unable to parse file/string without header for #{new.class}."
        result = {
          errors: errors,
          try: try,
          result: 'failed',
        }
        return result
      end
      header.each do |item|
        if item.respond_to?(:strip!)
          item.strip!
        end
        next if !item.respond_to?(:downcase!)
        item.downcase!
      end

      if rows[0].blank?
        errors.push "No records found in file/string for #{new.class}."
        result = {
          errors: errors,
          try: try,
          result: 'failed',
        }
        return result
      end

      # get payload based on csv
      payload = []
      rows.each do |row|
        if row[0].blank? && row[1].blank?
          payload_last = payload.last
          row.each_with_index do |item, count|
            next if item.blank?
            next if header[count].nil?
            if payload_last[header[count].to_sym].class != Array
              payload_last[header[count].to_sym] = [payload_last[header[count].to_sym]]
            end
            payload_last[header[count].to_sym].push item.strip
          end
          next
        end
        attributes = {}
        row.each_with_index do |item, count|
          next if !item
          next if header[count].blank?
          next if @csv_attributes_ignored&.include?(header[count].to_sym)
          attributes[header[count].to_sym] = if item.respond_to?(:strip)
                                               item.strip
                                             else
                                               item
                                             end
        end
        data[:fixed_params]&.each do |key, value|
          attributes[key] = value
        end
        payload.push attributes
      end

      stats = {
        created: 0,
        updated: 0,
      }

      # delete
      if delete == true
        stats[:deleted] = self.count
        if try == false
          destroy_all
        end
      end

      # create or update records
      csv_object_ids_ignored = @csv_object_ids_ignored || []
      records = []
      line_count = 0
      payload.each do |attributes|
        line_count += 1
        record = nil
        %i[id number name login email].each do |lookup_by|
          next if !attributes[lookup_by]
          params = {}
          params[lookup_by] = attributes[lookup_by]
          record = lookup(params)
          break if record
        end

        if attributes[:id].present? && !record
          errors.push "Line #{line_count}: unknown record with id '#{attributes[:id]}' for #{new.class}."
          next
        end

        if record && csv_object_ids_ignored.include?(record.id)
          errors.push "Line #{line_count}: unable to update record with id '#{attributes[:id]}' for #{new.class}."
          next
        end

        begin
          clean_params = association_name_to_id_convert(attributes)
        rescue => e
          errors.push "Line #{line_count}: #{e.message}"
          next
        end

        # create object
        Transaction.execute(disable_notification: true, reset_user_id: true) do
          UserInfo.current_user_id = clean_params[:updated_by_id] || clean_params[:created_by_id]
          if !record || delete == true
            stats[:created] += 1
            begin
              csv_verify_attributes(clean_params)
              clean_params = param_cleanup(clean_params)

              if !UserInfo.current_user_id
                clean_params[:created_by_id] = 1
                clean_params[:updated_by_id] = 1
              end
              record = new(clean_params)
              next if try == true
              record.associations_from_param(attributes)
              record.save!
            rescue => e
              errors.push "Line #{line_count}: #{e.message}"
              next
            end
          else
            stats[:updated] += 1
            next if try == true
            begin
              csv_verify_attributes(clean_params)
              clean_params = param_cleanup(clean_params)

              if !UserInfo.current_user_id
                clean_params[:updated_by_id] = 1
              end

              record.with_lock do
                record.associations_from_param(attributes)
                record.update!(clean_params)
              end
            rescue => e
              errors.push "Line #{line_count}: #{e.message}"
              next
            end
          end
        end

        records.push record
      end

      result = 'success'
      if errors.present?
        result = 'failed'
      end

      {
        stats: stats,
        records: records,
        errors: errors,
        try: try,
        result: result,
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
      csv_object_ids_ignored = @csv_object_ids_ignored || []
      records = where.not(id: csv_object_ids_ignored).offset(1).limit(23).to_a
      if records.count < 20
        record_ids = records.pluck(:id).concat(csv_object_ids_ignored)
        local_records = where.not(id: record_ids).limit(20 - records.count)
        records = records.concat(local_records)
      end
      records_attributes_with_association_names = []
      records.each do |record|
        record_attributes_with_association_names = record.attributes_with_association_names
        records_attributes_with_association_names.push record_attributes_with_association_names
        record_attributes_with_association_names.each do |key, value|
          next if value.class == ActiveSupport::HashWithIndifferentAccess
          next if value.class == Hash
          next if @csv_attributes_ignored&.include?(key.to_sym)
          next if key.match?(/_id$/)
          next if key.match?(/_ids$/)
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
          if record[key].class == ActiveSupport::TimeWithZone
            row.push record[key].iso8601
            next
          end
          if record[key].class == Array
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

serve methode to ignore model based on id

class Model < ApplicationModel
  include CanCsvImport
  csv_object_ids_ignored(1, 2, 3)
end

=end

    def csv_object_ids_ignored(*object_ids)
      @csv_object_ids_ignored = object_ids
    end

=begin

serve methode to ignore model attributes

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
      @csv_attributes_ignored = attributes
    end

=begin

serve methode to define if delete option is possible or not

class Model < ApplicationModel
  include CanCsvImport
  csv_delete_possible true

end

=end

    def csv_delete_possible(value)
      @csv_delete_possible = value
    end
  end
end
