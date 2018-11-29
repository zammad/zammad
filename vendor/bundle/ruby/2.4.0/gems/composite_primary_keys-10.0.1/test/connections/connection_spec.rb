require 'yaml'
require 'erb'

module CompositePrimaryKeys
  class ConnectionSpec
    def self.[](adapter)
      config[adapter.to_s].dup
    end

    private

    def self.config
      @config ||= begin
        # Find the file location
        path = File.join(PROJECT_ROOT, 'test', 'connections', 'databases.yml')

        # Run any erb code
        template = ERB.new(File.read(path))
        project_root = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
        data = template.result(binding)

        # And now to YAML
        YAML.load(data)
      end
    end
  end
end
