# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport < ApplicationModel
  store :data

  before_create :prepare_uuid

  def self.fetch
    {
      system_report: fetch_system_report,
    }
  end

  def self.fetch_with_create
    SystemReport.create(data: fetch, created_by_id: UserInfo.current_user_id || 1)
  end

  def self.plugins
    SystemReport::Plugin.list.map { |plugin| plugin.to_s.split('::').last }
  end

  def self.descriptions
    SystemReport::Plugin.list.map { |plugin| "#{plugin}::DESCRIPTION".constantize }
  end

  def self.fetch_system_report
    system_report = {}

    SystemReport::Plugin.list.each do |plugin|
      plugin_instance = plugin.new

      path = plugin_instance.class.path

      last_path = path.pop # Remove and store the last key

      nested_hash = path.inject(system_report) do |current_hash, key|
        current_hash[key] ||= {}
        current_hash[key]
      end

      # Set the value to the last key
      nested_hash[last_path] = plugin_instance.fetch
    end

    system_report
  end
  private_class_method :fetch_system_report

  def filename
    File.basename("zammad_system_report_#{Setting.get('fqdn')}_#{uuid}.json")
  end

  private

  def prepare_uuid
    self.uuid = SecureRandom.uuid
  end
end
