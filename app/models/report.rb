# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report

  def self.enabled?
    Setting.get('es_url').present?
  end

  def self.config
    config = {}
    config[:metric] = {}

    config[:metric][:count] = {
      name:    'count',
      display: 'Ticket Count',
      default: true,
      prio:    10_000,
    }
    backend = [
      {
        name:         'created',
        display:      'Created',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       { field: 'created_at' }
      },
      {
        name:         'closed',
        display:      'Closed',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       { field: 'close_at' }
      },
      {
        name:         'backlog',
        display:      'Backlog',
        selected:     true,
        dataDownload: false,
        adapter:      Report::TicketBacklog
      },
      {
        name:         'first_solution',
        display:      'First Solution',
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketFirstSolution
      },
      {
        name:         'reopened',
        display:      'Reopened',
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketReopened
      },
      {
        name:         'movedin',
        display:      'Moved in',
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketMoved,
        params:       { type: 'in' }
      },
      {
        name:         'movedout',
        display:      'Moved out',
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketMoved,
        params:       { type: 'out' }
      },
    ]
    config[:metric][:count][:backend] = backend

    config[:metric][:create_channels] = {
      name:    'create_channels',
      display: 'Create Channels',
      prio:    9000,
    }
    backend = [
      {
        name:         'phone_in',
        display:      'Phone (in)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'phone').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
            },
          },
        },
      },
      {
        name:         'phone_out',
        display:      'Phone (out)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'phone').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Agent').id,
            },
          }
        },
      },
      {
        name:         'email_in',
        display:      'Email (in)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'email').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
            },
          },
        },
      },
      {
        name:         'email_out',
        display:      'Email (out)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'email').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Agent').id,
            },
          },
        },
      },
      {
        name:         'web_in',
        display:      'Web (in)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'web').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
            },
          },
        },
      },
      {
        name:         'twitter_in',
        display:      'Twitter (in)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'twitter status').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
            },
          },
        },
      },
      {
        name:         'twitter_out',
        display:      'Twitter (out)',
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       {
          field:    'created_at',
          selector: {
            'create_article_type_id'   => {
              'operator' => 'is',
              'value'    => Ticket::Article::Type.lookup(name: 'twitter status').id,
            },
            'create_article_sender_id' => {
              'operator' => 'is',
              'value'    => Ticket::Article::Sender.lookup(name: 'Agent').id,
            },
          },
        },
      },
    ]
    config[:metric][:create_channels][:backend] = backend

    config[:metric][:communication] = {
      name:    'communication',
      display: 'Communication',
      prio:    7000,
    }
    backend = [
      {
        name:         'phone_in',
        display:      'Phone (in)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'phone',
          sender: 'Customer',
        },
      },
      {
        name:         'phone_out',
        display:      'Phone (out)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'phone',
          sender: 'Agent',
        },
      },
      {
        name:         'email_in',
        display:      'Email (in)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'email',
          sender: 'Customer',
        },
      },
      {
        name:         'email_out',
        display:      'Email (out)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'email',
          sender: 'Agent',
        },
      },
      {
        name:         'web_in',
        display:      'Web (in)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'web',
          sender: 'Customer',
        },
      },
      {
        name:         'twitter_in',
        display:      'Twitter (in)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'twitter status',
          sender: 'Customer',
        },
      },
      {
        name:         'twitter_out',
        display:      'Twitter (out)',
        selected:     true,
        dataDownload: false,
        adapter:      Report::ArticleByTypeSender,
        params:       {
          type:   'twitter status',
          sender: 'Agent',
        },
      },
    ]
    config[:metric][:communication][:backend] = backend

    config[:metric].each do |metric_key, metric_value|
      metric_value[:backend].each do |metric_backend|
        metric_backend[:name] = "#{metric_key}::#{metric_backend[:name]}"
      end
    end

    config
  end

end
