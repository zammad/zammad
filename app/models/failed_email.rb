# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FailedEmail < ApplicationModel
  def reprocess(params = {})
    ticket, _article, _user, _mail = Channel::EmailParser.new.process_with_timeout(params, data)

    raise __('Unknown error: Could not create a ticket from this email.') if !ticket

    destroy

    ticket
  rescue => e
    self.retries += 1
    self.parsing_error = e
    save!

    message = "Can't reprocess failed email '#{id}'. This was attempt # #{retries}."

    puts "ERROR: #{message}" # rubocop:disable Rails/Output
    puts "ERROR: #{e.inspect}" # rubocop:disable Rails/Output
    Rails.logger.error message
    Rails.logger.error e

    false
  end

  def parsing_error=(input)
    message = case input
              when StandardError
                "#{input.inspect}\n#{input.backtrace&.join("\n")}"
              else
                input
              end

    write_attribute :parsing_error, message
  end

  def self.by_filepath(filepath)
    id = Pathname
      .new(filepath)
      .basename
      .to_s
      .delete_suffix('.eml')

    return if id.include?('.')

    find_by(id:)
  end

  def self.reprocess_all(params = {})
    reorder(id: :desc)
      .in_batches
      .each_record
      .select { |elem| elem.reprocess(params) }
      .map { |elem| "#{elem.id}.eml" }
  end

  def self.generate_path
    Rails.root.join('tmp', "failed-email-#{SecureRandom.uuid}")
  end

  def self.export_all(path = generate_path)
    in_batches
      .each_record
      .map { |elem| elem.export(path) }
  end

  def export(path = self.class.generate_path)
    FileUtils.mkdir_p(path)

    full_path = path.join("#{id}.eml")

    File.binwrite full_path, data

    full_path
  end

  def self.import_all(path)
    Dir
      .each_child(path)
      .filter_map do |filename|
        next if !filename.ends_with?('.eml')

        import(path.join(filename))
      end
  end

  def self.import(filepath)
    failed_email = FailedEmail.by_filepath(filepath.basename)
    return if !failed_email

    new_data = File.binread filepath

    if new_data != failed_email.data
      failed_email.data = new_data
      failed_email.parsing_error = nil
      failed_email.save!
    end

    return if !failed_email.reprocess

    filepath.unlink

    filepath
  end
end
