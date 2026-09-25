#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Ensures that all precompiled gems in Gemfile.lock are available for every platform
#   Zammad is built for (packager.io, Docker, CI, development machines), so that none of them
#   falls back to compiling its native extension from source.
#
#   .gitlab/check_native_gem_platforms.rb [path/to/Gemfile.lock]

require 'bundler'

class CheckNativeGemPlatforms

  # `ruby` is the fallback for all unlisted platforms. Bundler silently drops it when a new gem
  #   is added to the Gemfile, which would break installations on those platforms.
  REQUIRED_PLATFORMS = %w[ruby x86_64-linux-gnu aarch64-linux-gnu x86_64-darwin arm64-darwin].freeze

  # An update can leave only the source variant of a gem in the lockfile, e.g. when its precompiled
  #   gems are not published yet. Listing the gems keeps them checked even then.
  PRECOMPILED_GEMS = %w[ffi google-protobuf nokogiri pg sass-embedded].freeze

  def self.run(lockfile_path)
    new(lockfile_path).run
  end

  def initialize(lockfile_path)
    @lockfile = Bundler::LockfileParser.new(File.read(lockfile_path))
    @errors   = []
  end

  def run
    puts 'Checking native gem platforms in Gemfile.lock…'

    check_required_platforms
    check_precompiled_gems

    if @errors.any?
      puts(@errors.map { |error| "  #{error}" })
      exit 1
    end

    puts "  #{@lockfile.platforms.size} platforms present, #{precompiled_gems.size} precompiled gems (#{precompiled_gems.keys.sort.join(', ')}) available for all #{binary_platforms.size} binary platforms."
    puts 'done.'
  end

  private

  def check_required_platforms
    platforms = @lockfile.platforms.map(&:to_s)

    (REQUIRED_PLATFORMS - platforms).each do |platform|
      @errors << "Platform '#{platform}' is missing, restore it with: bundle lock --add-platform #{platform}"
    end
  end

  def check_precompiled_gems
    precompiled_gems.each do |name, variants|
      # This script runs without ActiveSupport, so Array#exclude? is not available.
      @errors << "#{name} is a precompiled gem, add it to PRECOMPILED_GEMS in #{__FILE__}." if !PRECOMPILED_GEMS.include?(name) # rubocop:disable Rails/NegateInclude

      binary_platforms.each do |platform|
        next if variants.any? { |spec| binary?(spec) && Gem::Platform.new(spec.platform) === platform } # rubocop:disable Style/CaseEquality

        @errors << "#{name} #{variants.first.version} has no precompiled gem for #{platform}#{' and would need a Rust toolchain' if rust?(variants)}."
      end
    end
  end

  # A gem counts as precompiled if it is listed, or ships at least one platform variant. Rust-based
  #   gems count even without either, their source variant is recognizable by its rb_sys dependency.
  def precompiled_gems
    @precompiled_gems ||= @lockfile.specs.group_by(&:name).select do |name, variants|
      PRECOMPILED_GEMS.include?(name) || variants.any? { |spec| binary?(spec) } || rust?(variants)
    end
  end

  def rust?(variants)
    variants.any? { |spec| !binary?(spec) && spec.dependencies.any? { |dependency| dependency.name == 'rb_sys' } }
  end

  def binary?(spec)
    spec.platform != Gem::Platform::RUBY
  end

  def binary_platforms
    @binary_platforms ||= @lockfile.platforms.reject { |platform| platform == Gem::Platform::RUBY }
  end
end

CheckNativeGemPlatforms.run(ARGV[0] || File.expand_path('../Gemfile.lock', __dir__))
