# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ShowPackageUrl < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :packages, :url, :string, limit: 512
    Package.reset_column_information

    Package.find_each do |package|
      json_file = Package._get_bin(package.name, package.version)
      data = JSON.parse(json_file)
      next if data['url'].blank?

      package.update!(url: data['url'])
    end
  end
end
