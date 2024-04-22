# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Hardware < SystemReport::Plugin
  DESCRIPTION = __('Hardware (e.g. CPU cores, memory, disk space)').freeze

  def fetch
    {
      'total_memory'   => total_memory,
      'cpu_cores'      => Parallel.processor_count,
      'app_disk_space' => %w[total used free].zip(df_zammad_root).to_h,
    }
  end

  def total_memory
    open3_data&.dig('children')&.find { |entry| entry['description'] == 'Motherboard' }&.dig('children')&.find { |entry| entry['description'] == 'System memory' }&.dig('size')
  end

  def df_zammad_root
    `df #{Rails.root}`.lines.last.scan(%r{\d+}).map(&:to_i)[0..2]
  rescue
    []
  end

  def open3_data
    return {} if !binary_path

    data = execute
    return {} if data.blank?

    data
  end

  private

  def execute
    stdout, stderr, status = Open3.capture3(binary_path, '-json', binmode: true)
    if !status.success?
      Rails.logger.error("lshw failed: #{stderr}")
      return {}
    end

    begin
      JSON.parse(stdout)
    rescue
      Rails.logger.error("lshw failed: #{stdout}")
      {}
    end
  end

  def binary_path
    return ENV['LSHW_PATH'] if ENV['LSHW_PATH'] && File.executable?(ENV['LSHW_PATH'])

    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      bin = File.join(path, 'lshw')
      return bin if File.executable?(bin)
    end

    nil
  end
end
