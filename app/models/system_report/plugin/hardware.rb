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
    open3_data&.dig('children')&.find { |entry| entry['description'].downcase == 'motherboard' }&.dig('children')&.find { |entry| entry['description'].downcase == 'system memory' }&.dig('size')
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
    return data.first if data.is_a?(Array) # https://github.com/zammad/zammad/issues/5402

    data
  end

  private

  def execute
    stdout, stderr, status = Open3.capture3(binary_path, '-json', binmode: true)
    if !status.success?
      Rails.logger.error("lshw failed: #{stderr}")
      return {}
    end

    JSON.parse(stdout)
  rescue => e
    Rails.logger.error "lshw failed: #{e.message}"
    Rails.logger.error e
    {}
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
