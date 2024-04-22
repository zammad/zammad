# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Ruby < SystemReport::Plugin
  DESCRIPTION = __('Ruby information (version and installed gems)').freeze

  def fetch
    {
      interpreter: interpreter,
      gems:        gems,
    }.deep_symbolize_keys
  end

  private

  def interpreter
    {
      platform:     RUBY_PLATFORM,
      version:      RUBY_VERSION,
      engine:       RUBY_ENGINE,
      patchlevel:   RUBY_PATCHLEVEL,
      description:  RUBY_DESCRIPTION,
      release_date: RUBY_RELEASE_DATE,
    }
  end

  def gems
    gems = Bundler.load.specs.reject { |s| s.name == 'bundler' }
    gems.sort_by(&:name).to_h { |s| [s.name, s.version.to_s || s.git_version.to_s] }
  end
end
