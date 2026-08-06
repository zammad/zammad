# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Core driver of the Jira import: paginates through the issues of the
# configured project and creates the corresponding Zammad customers, tickets
# and articles (issue description + comments), preserving the original
# timestamps via import mode.
class Sequencer::Unit::Import::Jira::Issues < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Jira::Requester
  include ::Sequencer::Unit::Import::Jira::Adf

  uses :import_job, :dry_run

  PAGE_SIZE = 100
  STATISTICS_UPDATE_INTERVAL = 25

  def process
    UserInfo.current_user_id = 1

    init_statistics
    @statistics['Tickets'][:total] = total_issues

    if dry_run
      store_statistics
      return
    end

    processed = 0
    each_issue do |issue|
      import_issue(issue)
      processed += 1
      store_statistics if (processed % STATISTICS_UPDATE_INTERVAL).zero?
    end

    store_statistics
  end

  private

  # --- iteration -----------------------------------------------------------

  def each_issue
    next_page_token = nil

    loop do
      body = {
        jql:        jql,
        maxResults: PAGE_SIZE,
        fields:     %w[summary created updated status priority reporter assignee description issuetype],
      }
      body[:nextPageToken] = next_page_token if next_page_token.present?

      response = post_json('search/jql', body)
      break if response.blank?

      Array(response['issues']).each { |issue| yield(issue) }

      next_page_token = response['nextPageToken']
      break if response['isLast'] || next_page_token.blank?
    end
  end

  def total_issues
    response = post_json('search/approximate-count', { jql: jql })
    response.is_a?(Hash) ? response['count'].to_i : 0
  end

  def jql
    %(project = "#{project_key}" ORDER BY created ASC)
  end

  def project_key
    @project_key ||= Setting.get('import_jira_project_key')
  end

  # --- import --------------------------------------------------------------

  def import_issue(issue)
    return if ::Ticket.exists?(number: issue['id'])

    fields   = issue['fields'] || {}
    customer = ensure_customer(fields['reporter'])

    ticket = ::Ticket.create!(
      title:       ticket_title(issue, fields),
      number:      issue['id'],
      group_id:    default_group_id,
      customer_id: customer.id,
      state_id:    state_id(fields),
      priority_id: priority_id(fields),
      created_at:  fields['created'],
      updated_at:  fields['updated'] || fields['created'],
    )
    increment('Tickets', :created)

    create_description_article(ticket, issue, fields, customer)
    import_comments(ticket, issue)
  rescue => e
    logger.error "Jira import: failed to import issue #{issue['key']}: #{e.message}"
    increment('Tickets', :skipped)
  end

  def create_description_article(ticket, issue, fields, customer)
    ::Ticket::Article.create!(
      ticket_id:     ticket.id,
      body:          description_body(issue, fields),
      content_type:  'text/plain',
      type_id:       note_type_id,
      sender_id:     customer_sender_id,
      internal:      false,
      from:          reporter_from(fields['reporter']),
      message_id:    "jira-issue-#{issue['id']}@#{project_key}",
      created_at:    fields['created'],
      updated_at:    fields['created'],
      created_by_id: customer.id,
      updated_by_id: customer.id,
    )
    increment('Ticket::Article', :created)
  end

  def import_comments(ticket, issue)
    start_at = 0

    loop do
      response = get_json(
        "issue/#{issue['key']}/comment",
        params: { startAt: start_at, maxResults: PAGE_SIZE, orderBy: 'created' },
      )
      break if response.blank?

      Array(response['comments']).each do |comment|
        create_comment_article(ticket, issue, comment)
      end

      start_at += response['maxResults'].to_i
      break if start_at >= response['total'].to_i
    end
  end

  def create_comment_article(ticket, issue, comment)
    author = comment['author'] || {}

    ::Ticket::Article.create!(
      ticket_id:    ticket.id,
      body:         comment_body(comment, author),
      content_type: 'text/plain',
      type_id:      note_type_id,
      sender_id:    agent_sender_id,
      internal:     false,
      from:         author['displayName'],
      message_id:   "jira-comment-#{comment['id']}@#{project_key}",
      created_at:   comment['created'],
      updated_at:   comment['updated'] || comment['created'],
    )
    increment('Ticket::Article', :created)
  end

  # --- customers -----------------------------------------------------------

  def ensure_customer(reporter)
    reporter ||= {}
    email = reporter['emailAddress'].presence || "jira-#{reporter['accountId']}@import.invalid"

    existing = ::User.find_by(email: email.downcase)
    return existing if existing

    firstname, lastname = split_name(reporter['displayName'])
    user = ::User.create!(
      firstname: firstname,
      lastname:  lastname,
      email:     email,
      active:    true,
      role_ids:  ::Role.where(name: 'Customer').pluck(:id),
    )
    increment('Users', :created)
    user
  end

  def split_name(display_name)
    parts = display_name.to_s.strip.split
    return ['', ''] if parts.empty?
    return [parts.first, ''] if parts.size == 1

    [parts.first, parts[1..].join(' ')]
  end

  # --- body builders -------------------------------------------------------

  def ticket_title(issue, fields)
    "[#{issue['key']}] #{fields['summary']}"[0, 250]
  end

  def description_body(issue, fields)
    reporter = fields['reporter'] || {}
    <<~BODY.strip
      Imported from Jira — #{issue['key']}
      Link: #{issue_link(issue)}
      Type: #{fields.dig('issuetype', 'name')}
      Jira status: #{fields.dig('status', 'name')}
      Jira priority: #{fields.dig('priority', 'name')}
      Reporter: #{reporter['displayName']} <#{reporter['emailAddress'] || 'n/a'}>
      Assignee: #{fields.dig('assignee', 'displayName') || '-'}
      Created at: #{fields['created']}
      #{'-' * 40}

      #{adf_to_text(fields['description']).strip.presence || '(no description)'}
    BODY
  end

  def comment_body(comment, author)
    <<~BODY.strip
      Jira comment — #{author['displayName']} @ #{comment['created']}
      #{'-' * 40}
      #{adf_to_text(comment['body']).strip}
    BODY
  end

  def issue_link(issue)
    "#{Setting.get('import_jira_endpoint').to_s.chomp('/')}/browse/#{issue['key']}"
  end

  def reporter_from(reporter)
    reporter ||= {}
    reporter['emailAddress'].presence || reporter['displayName']
  end

  # --- mappings ------------------------------------------------------------

  # Maps the Jira status category (new / indeterminate / done) to a Zammad state.
  def state_id(fields)
    case fields.dig('status', 'statusCategory', 'key')
    when 'done'
      state_ids['closed']
    when 'indeterminate'
      state_ids['open']
    else
      state_ids['new']
    end
  end

  def priority_id(fields)
    case fields.dig('priority', 'name').to_s.downcase
    when 'highest', 'high'
      priority_ids['3 high']
    when 'low', 'lowest'
      priority_ids['1 low']
    else
      priority_ids['2 normal']
    end
  end

  def state_ids
    @state_ids ||= ::Ticket::State.where(name: %w[new open closed]).pluck(:name, :id).to_h
  end

  def priority_ids
    @priority_ids ||= ::Ticket::Priority.where(name: ['1 low', '2 normal', '3 high']).pluck(:name, :id).to_h
  end

  def default_group_id
    @default_group_id ||= (::Group.find_by(name: 'Users') || ::Group.first)&.id
  end

  def note_type_id
    @note_type_id ||= ::Ticket::Article::Type.find_by(name: 'note')&.id
  end

  def customer_sender_id
    @customer_sender_id ||= ::Ticket::Article::Sender.find_by(name: 'Customer')&.id
  end

  def agent_sender_id
    @agent_sender_id ||= ::Ticket::Article::Sender.find_by(name: 'Agent')&.id
  end

  # --- statistics ----------------------------------------------------------

  def init_statistics
    @statistics = {
      'Users'           => empty_stat,
      'Tickets'         => empty_stat,
      'Ticket::Article' => empty_stat,
    }
  end

  def empty_stat
    { total: 0, created: 0, updated: 0, skipped: 0, unchanged: 0, failed: 0 }
  end

  def increment(model_key, field)
    @statistics[model_key][field] += 1
    @statistics[model_key][:total] += 1 if field != :total && model_key != 'Tickets'
  end

  def store_statistics
    import_job.result = @statistics
    import_job.save!
  end
end
