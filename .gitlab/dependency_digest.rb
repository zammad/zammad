#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Posts a digest of dependency updates via webhook.
#
# Data sources:
#   1. Merged GitLab MRs with the label "dependencies" (Renovate, updatecli)
#      including the release notes Renovate embeds in MR bodies.
#   2. A diff of the monitored lockfiles over the same period, which also
#      catches transitive updates that never appear in an MR title.
#   3. OSV.dev advisories for every changed or added package (old and new
#      version), giving complete security coverage.
#   4. GitHub release notes, fetched selectively for transitive major updates,
#      new packages and OSV-flagged packages.
#
# All of this is assembled into a structured report, which is condensed into an
# impact-ranked digest; if that fails, a mechanical fallback digest is composed
# instead. Whenever the digest is degraded like that (LLM unreachable, or a
# fallback model had to be used), the post carries a footnote saying so and the
# script exits with code 2, which the CI job maps to "passed with warnings".
# The result is posted to an incoming webhook as an attachment whose color works
# as a traffic light: red when an advisory affects a version now in use, yellow
# when there are no security findings but major version jumps that deserve a
# look, green otherwise.
#
# Usage:
#   ruby .gitlab/dependency_digest.rb [--since DAYS] [--dry-run] [--payload] [--no-llm]
#
# Environment:
#   CI_API_V4_URL           GitLab API base URL (default: derived from the origin remote)
#   CI_PROJECT_ID           GitLab project id or URL-encoded path (default: derived from the origin remote)
#   GITLAB_API_TOKEN        GitLab token with read_api scope (falls back to RENOVATE_TOKEN)
#   WEBHOOK_URL             Incoming webhook (required unless --dry-run)
#   LLM_API_URL             Ollama base URL
#   LLM_MODEL               Ollama model family and size. The newest installed
#                           version of that family is picked automatically.
#   LLM_MODEL_PATTERN       optional regex overriding the derived family pattern
#   LLM_MODEL_FALLBACKS     optional, comma-separated models to try if nothing of the family is installed
#   LLM_API_KEY             optional bearer token, if the LLM endpoint is put behind auth
#   GITHUB_TOKEN            optional, raises the GitHub API rate limit for release notes

require 'json'
require 'net/http'
require 'optparse'
require 'time'
require 'uri'

class DependencyDigest
  GITLAB_API_URL     = ENV.fetch('CI_API_V4_URL', nil) # derived from the origin remote if unset
  GITLAB_PROJECT_ID  = ENV.fetch('CI_PROJECT_ID', nil) # dito, as URL-encoded project path
  GITLAB_TOKEN       = (ENV['GITLAB_API_TOKEN'] || ENV.fetch('RENOVATE_TOKEN', nil))&.strip
  MSG_MAX = 15_000 # post limit is 16383 chars, leave headroom.
  LLM_INPUT_MAX      = 160_000 # chars of report handed to the model
  GITHUB_FETCH_MAX   = 15 # release note lookups per run
  VERSION_KEYS       = %i[from to].freeze
  ATTACHMENT_COLORS  = { alert: '#d24b4e', warning: '#f0b429', ok: '#3db887' }.freeze
  LLM_API_URL = ENV.fetch('LLM_API_URL', '') # no default - unset means mechanical digest
  LLM_MODEL   = ENV.fetch('LLM_MODEL', '')
  LLM_MODEL_FALLBACKS = ENV.fetch('LLM_MODEL_FALLBACKS', '').split(',').map(&:strip).reject(&:empty?).freeze
  LLM_MODEL_PATTERN   = ENV.fetch('LLM_MODEL_PATTERN', '')
  EXIT_DEGRADED = 2 # digest was posted, but without the configured LLM
  LLM_NUM_CTX = Integer(ENV.fetch('LLM_NUM_CTX', '65536')) # context window requested from Ollama
  LLM_TIMEOUT = Integer(ENV.fetch('LLM_TIMEOUT', '900')) # seconds; loading the model alone can take over a minute
  NOTEWORTHY_JUMPS = %i[major added].freeze # get release notes fetched

  LOCKFILES = {
    'Gemfile.lock'                      => { parser: :parse_gemfile_lock, ecosystem: 'RubyGems' },
    'pnpm-lock.yaml'                    => { parser: :parse_pnpm_lock, ecosystem: 'npm' },
    # The chat widget is excluded from Renovate (public/**), so lockfile
    # changes there only ever happen manually - surface them here.
    'public/assets/chat/pnpm-lock.yaml' => { parser: :parse_pnpm_lock, ecosystem: 'npm' },
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are generating the weekly dependency update digest for the Zammad development
    team's chat channel. Zammad is a Ruby on Rails backend with a Vue +
    TypeScript frontend (Vite, Tiptap editor, GraphQL, pnpm) and RSpec/Capybara tests.

    The input is a structured markdown report with four sections:
      1. Security advisories (OSV, complete coverage of all changed packages)
      2. Direct updates (merged MRs, with release notes mined by Renovate)
      3. Transitive major updates & new packages (release notes fetched from GitHub)
      4. Remaining transitive changes (version bumps only)

    Produce a chat post in markdown, under 3500 characters,
    with exactly this structure:

    #### :package: Dependency digest <date range from the input>
    One overview sentence: number of merged MRs, number of independent projects
    changed (group monorepo families before counting), and the security status.

    **:rotating_light: Security** - always present. If section 1 lists advisories:
    one bullet per finding with package, advisory id, and whether the update fixed
    it or the new version is affected. Otherwise exactly one line:
    "No known advisories affect any changed package."

    **:warning: Worth checking** - breaking changes, deprecations and behavior
    changes that plausibly affect this codebase. One bullet per item:
    **project** `old` -> `new` (MR link if available) - what changed, and what a
    developer should check. Judge relevance against the Zammad stack described
    above; skip changes to APIs Zammad cannot plausibly use.

    **:eyes: Notable** - at most 6 bullets: new packages appearing in the lockfiles
    (always list these), major version jumps, and genuinely interesting features
    or fixes. Same bullet format.

    **Routine** - exactly one line collapsing everything else into counts, e.g.
    "Plus N minor and M patch-level transitive bumps across P projects - nothing
    noteworthy."

    Rules:
    - Group monorepo families and per-platform binaries as one item: all @tiptap/*
      packages are "Tiptap (39 packages)", @oxfmt/binding-* is "oxfmt".
    - Rank by impact on this codebase, never by version-jump size or input order.
    - State only what the input supports. If release notes are missing for an item
      you must mention, say so and include the diff link from the input. Never
      infer what "probably" changed from a version number.
    - Keep MR references like !13970 verbatim so the chat tool autolinks them.
    - Omit an empty "Worth checking" or "Notable" section entirely; never pad.
    - Complete sentences, no filler, no closing remarks.
  PROMPT

  def initialize(since_days:, dry_run: false, payload_only: false, no_llm: false)
    @since        = Time.now.utc - (since_days * 86_400)
    @dry_run      = dry_run
    @payload_only = payload_only
    @no_llm       = no_llm
  end

  def run
    mrs        = fetch_dependency_mrs
    lock_diffs = lockfile_changes
    changes    = normalize_changes(lock_diffs, mrs)
    advisories = osv_findings(changes)
    notes      = fetch_release_notes(interesting_changes(changes, advisories))
    report     = build_report(mrs, changes, advisories, notes)

    if @payload_only
      puts report
      return
    end

    message = llm_digest(report) || fallback_digest(mrs, lock_diffs, changes, advisories)
    message = [message, degradation_note].compact.join("\n\n")
    message = "#{message[0, MSG_MAX]}\n\n_(truncated)_" if message.length > MSG_MAX

    if @dry_run
      puts message
    else
      post_to_webhook(message, status: digest_status(changes, advisories))
    end

    exit EXIT_DEGRADED if degraded?
  end

  private

  def date_range
    "#{@since.strftime('%Y-%m-%d')} -> #{Time.now.utc.strftime('%Y-%m-%d')}"
  end

  # Footnote for the post when the digest did not come from an LLM. Which endpoint,
  # model or error was involved is infrastructure detail and stays in the job log.
  # Intentionally skipping the LLM (--no-llm) is not a degradation.
  def degradation_note
    return '_:warning: This digest was generated without AI summarization._' if @llm_failure

    nil
  end

  # Degraded runs (mechanical fallback or fallback model) exit with EXIT_DEGRADED so
  # the CI job shows "passed with warnings"; the reason is only in the job log.
  def degraded?
    !@llm_failure.nil? || !!@llm_fallback
  end

  # :alert   - an advisory affects a version that is now in use
  # :warning - no security findings, but major version jumps worth checking
  # :ok      - routine updates only
  def digest_status(changes, advisories)
    return :alert   if advisories.any? { |finding| finding[:status] == :affected }
    return :warning if changes.any? { |change| change[:jump] == :major }

    :ok
  end

  #
  # GitLab: merged MRs with label "dependencies"
  #

  def fetch_dependency_mrs
    mrs = gitlab_get('merge_requests', state: 'merged', labels: 'dependencies', updated_after: @since.iso8601, per_page: 100)
    mrs
      .select { |mr| Time.parse(mr['merged_at']) >= @since } # rubocop:disable Rails/TimeZone
      .sort_by { |mr| mr['merged_at'] }
      .map     { |mr| parse_mr(mr) }
  end

  def parse_mr(merge_request)
    {
      iid:      merge_request['iid'],
      title:    merge_request['title'].delete_prefix('Maintenance: '),
      url:      merge_request['web_url'],
      packages: parse_renovate_table(merge_request['description'].to_s),
      notes:    parse_release_notes(merge_request['description'].to_s),
    }
  end

  # Renovate MR bodies contain a table like:
  #   | [vue-tsc](https://...) | [`^3.3.9` -> `^3.3.10`](https://...) | ...
  def parse_renovate_table(description)
    description.each_line.filter_map do |line|
      next if !line.start_with?('| [')

      package = line[%r{\A\|\s*\[([^\]]+)\]}, 1]
      change  = line.match(%r{`([^`]+)`\s*(?:→|->)\s*`([^`]+)`})
      next if !package || !change

      { name: package.gsub('&#8203;', ''), from: change[1], to: change[2] }
    end
  end

  # Renovate embeds changelog excerpts as <details> blocks below "### Release Notes".
  def parse_release_notes(description)
    section = description[%r{^### Release Notes.*\z}m]
    return [] if !section

    section.scan(%r{<details>\s*<summary>(.*?)</summary>(.*?)</details>}m).map do |summary, body|
      { source: summary.gsub('&#8203;', '').strip, text: strip_markup(body) }
    end
  end

  def strip_markup(text)
    text
      .gsub(%r{</?[a-z][^>]*>}i, '')
      .gsub('&#8203;', '')
      .gsub(%r{^\s*\[!\[.*$}, '') # badge images
      .gsub(%r{\n{3,}}, "\n\n")
      .strip
  end

  #
  # Lockfile diff: catches transitive updates as well
  #

  def lockfile_changes
    base = `git rev-list -1 --before="#{@since.iso8601}" HEAD`.strip
    if base.empty?
      warn 'No commit older than the comparison window in the checkout (GIT_DEPTH too small?) - skipping the lockfile diff'
      return {}
    end

    LOCKFILES.filter_map do |file, config|
      old_content = `git show #{base}:#{file} 2>/dev/null`
      next if old_content.empty?

      diff = diff_versions(send(config[:parser], old_content), send(config[:parser], File.read(file)))
      next if diff.values.all?(&:empty?)

      [file, diff]
    end.to_h
  end

  # The parsers map each name to the list of its installed versions - a lockfile
  #   can pin the same package at several versions at once. Dropped and gained
  #   versions of a name are paired up (lowest with lowest) into from -> to
  #   changes; a surplus on either side is a version that was added to or
  #   removed from the tree alongside one that is still installed, not a jump.
  def diff_versions(old_versions, new_versions)
    diff = { changed: [], added: [], removed: [] }

    (old_versions.keys | new_versions.keys).each do |name|
      dropped = sort_versions((old_versions[name] || []) - (new_versions[name] || []))
      gained  = sort_versions((new_versions[name] || []) - (old_versions[name] || []))

      pair_count = [dropped.size, gained.size].min
      pair_count.times { |i| diff[:changed] << { name: name, from: dropped[i], to: gained[i] } }
      gained[pair_count..].each  { |version| diff[:added]   << { name: name, to: version } }
      dropped[pair_count..].each { |version| diff[:removed] << { name: name, from: version } }
    end

    diff
  end

  def sort_versions(versions)
    versions.sort_by do |version|
      normalized = version.tr('-', '.')
      Gem::Version.correct?(normalized) ? Gem::Version.new(normalized) : Gem::Version.new('0')
    end
  end

  def parse_gemfile_lock(content)
    in_gem_specs = false
    content.each_line.with_object({}) do |line, result|
      in_gem_specs = true  if line.start_with?('GEM')
      in_gem_specs = false if line.match?(%r{\A[A-Z]}) && !line.start_with?('GEM')
      next if !in_gem_specs

      name, version = line.match(%r{\A    (\S+) \(([^)]+)\)\s*\z})&.captures
      (result[name] ||= []) << version if name
    end
  end

  def parse_pnpm_lock(content)
    section = content[%r{^packages:\n(.*?)(?=^\S|\z)}m]
    return {} if !section

    section.each_line.with_object({}) do |line, result|
      key = line.match(%r{\A  '?([^':\s]+)'?:\s*\z})&.captures&.first
      next if !key

      at = key.rindex('@')
      next if !at || at.zero?

      (result[key[0...at]] ||= []) << key[(at + 1)..]
    end
  end

  #
  # Normalized change list (one entry per changed/added package)
  #

  def normalize_changes(lock_diffs, mrs)
    direct = mrs.flat_map { |mr| mr[:packages].map { |package| package[:name] } }.to_set

    lock_diffs.flat_map do |file, diff|
      ecosystem = LOCKFILES[file][:ecosystem]
      entries   = diff[:changed].map { |change| change.merge(kind: :changed) } +
                  diff[:added].map { |change| change.merge(kind: :added) }
      entries.map do |change|
        change.merge(
          ecosystem: ecosystem,
          direct:    direct.include?(change[:name]),
          jump:      change[:kind] == :added ? :added : semver_jump(change[:from], change[:to])
        )
      end
    end
  end

  def semver_jump(from, to)
    from_parts = from.to_s.split('.').map(&:to_i)
    to_parts   = to.to_s.split('.').map(&:to_i)
    return :major if to_parts[0] != from_parts[0]
    return :minor if to_parts[1] != from_parts[1]

    :patch
  end

  #
  # OSV.dev: advisories for old and new versions of every change
  #

  def osv_findings(changes)
    queries = changes.flat_map do |change|
      VERSION_KEYS.filter_map do |key|
        next if !change[key]

        { package: { name: change[:name], ecosystem: change[:ecosystem] }, version: change[key].to_s }
      end
    end
    return [] if queries.empty?

    response = Net::HTTP.post(URI('https://api.osv.dev/v1/querybatch'), { queries: queries }.to_json, 'Content-Type' => 'application/json')
    return [] if !response.is_a?(Net::HTTPSuccess)

    vulns_by_query = JSON.parse(response.body)['results'].map { |result| (result['vulns'] || []).map { |vuln| vuln['id'] } }
    collect_osv_findings(changes, queries, vulns_by_query)
  rescue => e
    warn "OSV lookup failed: #{e.class}: #{e.message}"
    []
  end

  def collect_osv_findings(changes, queries, vulns_by_query)
    vulns_for = queries.zip(vulns_by_query).to_h { |query, vulns| [[query[:package][:name], query[:version]], vulns] }

    changes.filter_map do |change|
      old_vulns = vulns_for[[change[:name], change[:from].to_s]] || []
      new_vulns = vulns_for[[change[:name], change[:to].to_s]] || []

      if new_vulns.any?
        { name: change[:name], version: change[:to], ids: new_vulns, status: :affected }
      elsif old_vulns.any? && change[:kind] == :changed
        { name: change[:name], version: change[:to], ids: old_vulns, status: :fixed }
      end
    end
  end

  #
  # GitHub release notes for transitive majors, new and OSV-flagged packages
  #

  def interesting_changes(changes, advisories)
    flagged = advisories.to_set { |finding| finding[:name] }
    changes.reject { |change| change[:direct] }
      .select { |change| NOTEWORTHY_JUMPS.include?(change[:jump]) || flagged.include?(change[:name]) }
  end

  def fetch_release_notes(changes)
    changes.first(GITHUB_FETCH_MAX).filter_map do |change|
      repo = github_repo_for(change)
      next if !repo

      releases = releases_between(repo, change)

      # Keyed by name AND target version: the two pnpm lockfiles share many
      #   package names at different versions, which must not overwrite each other.
      [[change[:name], change[:to]], { repo: repo, releases: releases }] if releases.any?
    end.to_h
  end

  def github_repo_for(change)
    url =
      if change[:ecosystem] == 'RubyGems'
        meta = JSON.parse(Net::HTTP.get(URI("https://rubygems.org/api/v1/gems/#{change[:name]}.json")))
        meta['source_code_uri'] || meta['homepage_uri']
      else
        meta = JSON.parse(Net::HTTP.get(URI("https://registry.npmjs.org/#{change[:name].gsub('/', '%2F')}/latest")))
        meta.dig('repository', 'url')
      end
    url&.[](%r{github\.com[/:]([^/]+/[^/.]+)}, 1)
  rescue => e
    warn "Repository lookup for #{change[:name]} failed (#{e.class}: #{e.message})"
    nil
  end

  def releases_between(repo, change)
    uri     = URI("https://api.github.com/repos/#{repo}/releases?per_page=100")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}" if !ENV['GITHUB_TOKEN'].to_s.empty?
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    if !response.is_a?(Net::HTTPSuccess)
      warn "GitHub releases for #{repo} unavailable (HTTP #{response.code})"
      return []
    end

    JSON.parse(response.body)
      .select { |release| release_in_range?(release, change) }
      .map    { |release| { tag: release['tag_name'], body: (release['body'] || '')[0, 1500] } }
  rescue => e
    warn "GitHub releases for #{repo} failed (#{e.class}: #{e.message})"
    []
  end

  def release_in_range?(release, change)
    version = release['tag_name'][%r{\d+\.\d+\.\d+(?:[-.][\w.]+)?\z}]
    return false if !version
    # Monorepos tag per package ("@scope/name@1.2.3") - require the package name.
    # Plain Ruby here, no ActiveSupport - so no String#exclude?.
    return false if release['tag_name'].include?('@') && !release['tag_name'].include?(change[:name]) # rubocop:disable Rails/NegateInclude

    from  = Gem::Version.new(change[:from].to_s.empty? ? '0' : change[:from])
    to    = Gem::Version.new(change[:to])
    value = Gem::Version.new(version)
    value > from && value <= to
  rescue ArgumentError
    false
  end

  #
  # Report: the structured input handed to the LLM (or dumped via --payload)
  #

  def build_report(mrs, changes, advisories, notes)
    sections = [
      "# Dependency changes for zammad/zammad, #{date_range}",
      report_security_section(changes, advisories),
      report_mr_section(mrs),
      report_transitive_section(changes, advisories, notes),
      report_remainder_section(changes),
    ]
    sections.join("\n\n")[0, LLM_INPUT_MAX]
  end

  def report_security_section(changes, advisories)
    lines = advisories.map do |finding|
      case finding[:status]
      when :affected then "- #{finding[:name]} #{finding[:version]} is AFFECTED by #{finding[:ids].join(', ')}"
      when :fixed    then "- #{finding[:name]}: the update to #{finding[:version]} fixes #{finding[:ids].join(', ')}"
      end
    end
    lines = ['No known advisories affect any changed or added package version.'] if lines.empty?

    "## 1. Security advisories (OSV.dev, all #{changes.size} changed/added packages checked)\n#{lines.join("\n")}"
  end

  def report_mr_section(mrs)
    parts = mrs.map do |mr|
      packages = mr[:packages].map { |package| "#{package[:name]} #{package[:from]} -> #{package[:to]}" }.join(', ')
      notes    = mr[:notes].map { |note| "Release notes (#{note[:source]}):\n#{note[:text][0, 2000]}" }
      ["### MR !#{mr[:iid]}: #{mr[:title]}", (packages.empty? ? nil : "Packages: #{packages}"), *notes].compact.join("\n")
    end

    "## 2. Direct updates (#{mrs.size} merged MRs, release notes mined by Renovate)\n\n#{parts.join("\n\n")}"
  end

  def report_transitive_section(changes, advisories, notes)
    parts = interesting_changes(changes, advisories).map do |change|
      heading = change[:kind] == :added ? "#{change[:name]} #{change[:to]} (NEW, #{change[:ecosystem]})" : "#{change[:name]} #{change[:from]} -> #{change[:to]} (#{change[:jump]}, #{change[:ecosystem]})"
      body    =
        if (fetched = notes[[change[:name], change[:to]]])
          fetched[:releases].first(4).map { |release| "[#{release[:tag]}]\n#{release[:body]}" }.join("\n")
        else
          "(no release notes found - #{fallback_reference_link(change)})"
        end
      "### #{heading}\n#{body}"
    end
    return '## 3. Transitive major updates & new packages: none this week' if parts.empty?

    "## 3. Transitive major updates & new packages (release notes fetched from GitHub)\n\n#{parts.join("\n\n")}"
  end

  # A version diff link only makes sense for a package that had a previous
  #   version - an added package gets its registry page instead.
  def fallback_reference_link(change)
    if change[:kind] == :added
      if change[:ecosystem] == 'npm'
        "registry: https://www.npmjs.com/package/#{change[:name]}/v/#{change[:to]}"
      else
        "registry: https://rubygems.org/gems/#{change[:name]}/versions/#{change[:to]}"
      end
    else
      "diff: https://renovatebot.com/diffs/#{change[:ecosystem] == 'npm' ? 'npm' : 'rubygems'}/#{change[:name].gsub('/', '%2F')}/#{change[:from]}/#{change[:to]}"
    end
  end

  def report_remainder_section(changes)
    rest  = changes.reject { |change| change[:direct] || NOTEWORTHY_JUMPS.include?(change[:jump]) }
    lines = %i[minor patch].map do |jump|
      entries = rest.select { |change| change[:jump] == jump }
      "#{jump.capitalize}: #{entries.map { |change| "#{change[:name]} #{change[:from]}->#{change[:to]}" }.join(', ')}"
    end

    "## 4. Remaining transitive changes (version bumps only)\n#{lines.join("\n")}"
  end

  #
  # Digest: LLM with mechanical fallback
  #

  def llm_digest(report)
    return nil if @no_llm || LLM_API_URL.empty? || LLM_MODEL.empty?

    @llm_model = resolve_llm_model

    uri      = URI("#{LLM_API_URL}/api/chat")
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: LLM_TIMEOUT) do |http|
      http.request(llm_request(uri, report))
    end
    raise "HTTP #{response.code}: #{response.body[0, 200]}" if !response.is_a?(Net::HTTPSuccess)

    result = JSON.parse(response.body)
    report_llm_usage(result)

    text = result.dig('message', 'content').to_s.strip
    text.empty? ? nil : text
  rescue => e
    @llm_failure = e.message[0, 120]
    warn "LLM digest failed (#{@llm_failure}), falling back to the mechanical digest"
    nil
  end

  def llm_request(uri, report)
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request['Authorization'] = "Bearer #{ENV['LLM_API_KEY']}" if !ENV['LLM_API_KEY'].to_s.empty?
    request.body = {
      model:    @llm_model,
      stream:   false,
      think:    false,
      options:  { num_ctx: LLM_NUM_CTX, num_predict: 4_000, temperature: 0.2 },
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: "Here is this week's report:\n\n#{report}" },
      ],
    }.to_json
    request
  end

  # Picks the newest installed model of the configured family (somemodel1.2:7b -> somemodel1.3:7b
  # once that shows up), falling back to LLM_MODEL_FALLBACKS if nothing of the family is
  # installed. If the tag list cannot be fetched, the configured model is tried as-is.
  def resolve_llm_model
    installed = installed_llm_models
    return LLM_MODEL if installed.nil?

    newest = newest_family_model(installed)
    if newest
      warn "using #{newest} (newest installed model of the #{LLM_MODEL} family)" if newest != LLM_MODEL
      return newest
    end

    fallback = LLM_MODEL_FALLBACKS.find { |name| installed.include?(name) || installed.include?("#{name}:latest") }
    if !fallback
      warn "models installed on #{LLM_API_URL}: #{installed.join(', ')}"
      fallbacks = LLM_MODEL_FALLBACKS.empty? ? 'no fallbacks configured' : "fallbacks #{LLM_MODEL_FALLBACKS.join(', ')}"
      raise "nothing of the #{LLM_MODEL} family installed on #{URI(LLM_API_URL).host} (#{fallbacks})"
    end

    warn "nothing of the #{LLM_MODEL} family installed, using fallback #{fallback}"
    @llm_fallback = true
    fallback
  end

  def installed_llm_models
    uri     = URI("#{LLM_API_URL}/api/tags")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{ENV['LLM_API_KEY']}" if !ENV['LLM_API_KEY'].to_s.empty?
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: 60) do |http|
      http.request(request)
    end
    return nil if !response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('models', []).map { |model| model['name'] } # rubocop:disable Rails/Pluck
  end

  # "somemodel1.2:7b" -> /\Asomemodel\d+(?:\.\d+)*:7b\z/ - same name stem, any version, same size tag.
  def llm_family_pattern
    return Regexp.new(LLM_MODEL_PATTERN) if !LLM_MODEL_PATTERN.empty?

    name, tag = LLM_MODEL.split(':', 2)
    stem      = name[%r{\A(.*?)\d+(?:\.\d+)*\z}, 1]
    return %r{\A#{Regexp.escape(LLM_MODEL)}\z}o if !stem

    %r{\A#{Regexp.escape(stem)}\d+(?:\.\d+)*:#{Regexp.escape(tag.to_s)}\z}
  end

  def newest_family_model(installed)
    installed
      .grep(llm_family_pattern)
      .max_by { |name| Gem::Version.new(name[%r{\d+(?:\.\d+)*(?=:|\z)}] || '0') }
  end

  # Goes to stderr so the digest itself stays clean on stdout (--dry-run).
  def report_llm_usage(result)
    warn format('LLM usage (%s): %d prompt tokens, %d generated tokens, %.0fs total (model load %.0fs)',
                @llm_model, result['prompt_eval_count'].to_i, result['eval_count'].to_i,
                result['total_duration'].to_i / 1e9, result['load_duration'].to_i / 1e9)
    warn 'LLM output was cut off at num_predict - consider a shorter report or a higher limit' if result['done_reason'] == 'length'
  end

  def fallback_digest(mrs, lock_diffs, changes, advisories)
    [
      "#### :package: Dependency digest #{date_range}",
      fallback_security(changes, advisories),
      compose_mrs(mrs),
      keyword_highlights(mrs),
      compose_lock_diffs(lock_diffs, mrs),
    ].compact.join("\n\n")
  end

  def fallback_security(changes, advisories)
    affected = advisories.select { |finding| finding[:status] == :affected }
    fixed    = advisories.select { |finding| finding[:status] == :fixed }

    lines = affected.map { |finding| "- :rotating_light: **#{finding[:name]}** #{finding[:version]} is affected by #{finding[:ids].join(', ')}" }
    lines += fixed.map { |finding| "- :white_check_mark: **#{finding[:name]}**: update to #{finding[:version]} fixes #{finding[:ids].join(', ')}" }
    lines = ["No known advisories affect any changed package (#{changes.size} checked via OSV.dev)."] if lines.empty?

    "**:rotating_light: Security**\n#{lines.join("\n")}"
  end

  def compose_mrs(mrs)
    return 'No dependency MRs were merged in this period.' if mrs.empty?

    rows = mrs.map do |mr|
      changes = mr[:packages].map { |package| "#{package[:name]} `#{package[:from]}` → `#{package[:to]}`" }.join(', ')
      changes = mr[:title] if changes.empty?
      "| [!#{mr[:iid]}](#{mr[:url]}) | #{changes} |"
    end

    "**Merged dependency MRs (#{mrs.count})**\n\n| MR | Changes |\n|---|---|\n#{rows.join("\n")}"
  end

  def keyword_highlights(mrs)
    notes = mrs.flat_map { |mr| mr[:notes].map { |note| "## #{note[:source]} (#{mr[:title]})\n#{note[:text]}" } }
    hits  = notes.filter_map do |note|
      source = note.lines.first.to_s.delete_prefix('## ').strip
      lines  = note.lines.grep(%r{breaking|security|vulnerab|deprecat|CVE-}i)
      next if lines.empty?

      "- **#{source}**:\n#{lines.uniq.first(3).map { |line| "  > #{line.strip}" }.join("\n")}"
    end
    return nil if hits.empty?

    "**Highlights from release notes** _(keyword-based fallback, the LLM digest was unavailable)_\n#{hits.join("\n")}"
  end

  def compose_lock_diffs(lock_diffs, mrs)
    return nil if lock_diffs.empty?

    known    = mrs.flat_map { |mr| mr[:packages].map { |package| package[:name] } }.to_set
    sections = lock_diffs.map { |file, diff| compose_lock_diff_section(file, diff, known) }

    "**Transitive/lockfile changes** (not part of an MR title)\n#{sections.join("\n")}"
  end

  def compose_lock_diff_section(file, diff, known)
    transitive = diff[:changed].reject { |change| known.include?(change[:name]) }
    lines = []
    lines << format_lock_entries(transitive) { |entry| "#{entry[:name]} `#{entry[:from]}` → `#{entry[:to]}`" }
    lines << format_lock_entries(diff[:added], prefix: 'added: ') { |entry| "#{entry[:name]} `#{entry[:to]}`" }
    lines << format_lock_entries(diff[:removed], prefix: 'removed: ') { |entry| "#{entry[:name]} `#{entry[:from]}`" }
    "`#{file}`: #{lines.compact.join("\n")}"
  end

  def format_lock_entries(entries, prefix: '', limit: 25, &)
    return nil if entries.empty?

    listed = entries.first(limit).map(&).join(', ')
    more   = entries.count > limit ? " _and #{entries.count - limit} more_" : ''
    "#{prefix}#{listed}#{more}"
  end

  #
  # Webhook and GitLab API
  #

  def post_to_webhook(message, status:)
    webhook = ENV.fetch('WEBHOOK_URL') { abort 'WEBHOOK_URL is not set (use --dry-run for local testing)' }

    payload = {
      username:    'Dependency Digest',
      attachments: [{ color: ATTACHMENT_COLORS.fetch(status), text: message }],
    }
    response = Net::HTTP.post(URI(webhook), payload.to_json, 'Content-Type' => 'application/json')
    abort "Webhook delivery failed: #{response.code} #{response.body}" if !response.is_a?(Net::HTTPSuccess)

    puts 'Digest posted.'
  end

  # Outside CI (no CI_* variables), API URL and project are derived from the origin
  # remote, so the script works in any clone without configuration.
  def gitlab_api_url
    @gitlab_api_url ||= GITLAB_API_URL || "https://#{git_remote[:host]}/api/v4"
  end

  def gitlab_project
    @gitlab_project ||= GITLAB_PROJECT_ID || URI.encode_www_form_component(git_remote[:path])
  end

  def git_remote
    @git_remote ||= begin
      url = `git remote get-url origin`.strip
      {
        host: url[%r{@([^:/]+)[:/]}, 1] || URI(url).host,
        path: url[%r{[:/]([\w.-]+/[\w.-]+?)(?:\.git)?\z}, 1],
      }
    end
  end

  def gitlab_get(path, params)
    uri = URI("#{gitlab_api_url}/projects/#{gitlab_project}/#{path}")
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    request['PRIVATE-TOKEN'] = GITLAB_TOKEN if GITLAB_TOKEN

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    abort "GitLab API request failed: #{response.code} #{response.body[0, 200]}" if !response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end

if $PROGRAM_NAME == __FILE__
  options = { since_days: 7 }
  OptionParser.new do |parser|
    parser.on('--since DAYS', Integer, 'Look back this many days (default: 7)') { |days| options[:since_days] = days }
    parser.on('--dry-run', 'Print the digest instead of posting it')            { options[:dry_run] = true }
    parser.on('--payload', 'Print the report that would be handed to the LLM')  { options[:payload_only] = true }
    parser.on('--no-llm', 'Skip the LLM and compose the mechanical digest') { options[:no_llm] = true }
  end.parse!

  DependencyDigest.new(**options).run
end
