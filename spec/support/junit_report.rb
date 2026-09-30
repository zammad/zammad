# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lets GitLab list all examples in the test reports of pipelines and merge requests.
if ENV['CI_JUNIT_REPORT_DIR'].present?
  RSpec.configure { |config| config.add_formatter('RspecJunitFormatter', File.join(ENV['CI_JUNIT_REPORT_DIR'], 'rspec.xml')) }
end
