# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue5015MigrateIssueLinks < ActiveRecord::Migration[7.0]

  # returns the gid only if their further successful usage is validated
  def get_validated_issue_gid(client, issue_link)
    begin
      issue_by_url = client.issue_by_url(issue_link)

      # validate successful issue request
      return if issue_by_url.blank? || !issue_by_url.key?(:gid)

      issue_by_gid = client.issue_by_gid(issue_by_url[:gid])

      # validate whether an issue request using the gid is also successful with the same content in response
      return if issue_by_gid.blank? || !issue_by_gid.key?(:gid) || issue_by_url.sort != issue_by_gid.sort

      # everything is fine
      issue_by_url[:gid]
    rescue => e
      Rails.logger.error(e.inspect)
      nil
    end
  end

  def migrate_ticket_github_links(ticket) # rubocop:disable Metrics/AbcSize
    ticket_changed = false
    if ticket.preferences.key?(:github) && ticket.preferences[:github].key?(:issue_links)
      original_github_issue_links = ticket.preferences[:github][:issue_links].map(&:clone)
      ticket.preferences[:github][:gids] = []

      github_config = Setting.get('github_config')
      github = ::GitHub.new(github_config['endpoint'], github_config['api_token'])

      # iterate over copied items to be able to dynamically remove successfully processed links from the real ticket preferences
      original_github_issue_links.each do |issue_link|
        gid = get_validated_issue_gid(github, issue_link)

        # validate successful gid response
        next if gid.nil?

        # finish this issue_link migration
        ticket.preferences[:github][:gids].push(gid)
        ticket.preferences[:github][:issue_links].delete(issue_link)
        ticket_changed = true
      end

      # remove old issue_links array only if all links have been successfully migrated to gids, otherwise running in dual mode
      if Array(original_github_issue_links).uniq.length == Array(ticket.preferences[:github][:gids]).uniq.length && Array(ticket.preferences[:github][:issue_links]).uniq.empty?
        ticket.preferences[:github].delete(:issue_links)
        ticket_changed = true
      end
    end
    ticket_changed
  end

  def migrate_ticket_gitlab_links(ticket) # rubocop:disable Metrics/AbcSize
    ticket_changed = false
    if ticket.preferences.key?(:gitlab) && ticket.preferences[:gitlab].key?(:issue_links)
      original_gitlab_issue_links = ticket.preferences[:gitlab][:issue_links].map(&:clone)
      ticket.preferences[:gitlab][:gids] = []

      gitlab_config = Setting.get('gitlab_config')
      gitlab = ::GitLab.new(gitlab_config['endpoint'], gitlab_config['api_token'], verify_ssl: gitlab_config['verify_ssl'])

      # iterate over copied items to be able to dynamically remove successfully processed links from the real ticket preferences
      original_gitlab_issue_links.each do |issue_link|
        gid = get_validated_issue_gid(gitlab, issue_link)

        # validate successful gid response
        next if gid.nil?

        # finish this issue_link migration
        ticket.preferences[:gitlab][:gids].push(gid)
        ticket.preferences[:gitlab][:issue_links].delete(issue_link)
        ticket_changed = true
      end

      # remove old issue_links array only if all links have been successfully migrated to gids, otherwise running in dual mode
      if Array(original_gitlab_issue_links).uniq.length == Array(ticket.preferences[:gitlab][:gids]).uniq.length && Array(ticket.preferences[:gitlab][:issue_links]).uniq.empty?
        ticket.preferences[:gitlab].delete(:issue_links)
        ticket_changed = true
      end
    end
    ticket_changed
  end

  def up
    SearchIndexBackend.search('(preferences.github.issue_links: *) OR (preferences.gitlab.issue_links: *)', 'Ticket').each do |result|
      ticket = Ticket.find_by(id: result[:id])
      next if ticket.blank?

      # use ticket_changed boolean to avoid unnecessary ticket saving operations
      ticket_changed = migrate_ticket_github_links(ticket)
      ticket_changed = migrate_ticket_gitlab_links(ticket) || ticket_changed

      if ticket_changed
        ticket.save!
      end
    end
  end
end
