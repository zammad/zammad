# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Report

  def self.enabled?
    Setting.get('es_url').present?
  end

  def self.config
    config = {}
    config[:metric] = {}

    config[:metric][:count] = {
      name:    'count',
      display: __('Ticket Count'),
      default: true,
      prio:    10_000,
    }
    backend = [
      {
        name:         'created',
        display:      __('Created'),
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       { field: 'created_at' }
      },
      {
        name:         'closed',
        display:      __('Closed'),
        selected:     true,
        dataDownload: true,
        adapter:      Report::TicketGenericTime,
        params:       { field: 'close_at' }
      },
      {
        name:         'backlog',
        display:      __('Backlog'),
        selected:     true,
        dataDownload: false,
        adapter:      Report::TicketBacklog
      },
      {
        name:         'first_solution',
        display:      __('First Solution'),
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketFirstSolution
      },
      {
        name:         'reopened',
        display:      __('Reopened'),
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketReopened
      },
      {
        name:         'movedin',
        display:      __('Moved in'),
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketMoved,
        params:       { type: 'in' }
      },
      {
        name:         'movedout',
        display:      __('Moved out'),
        selected:     false,
        dataDownload: true,
        adapter:      Report::TicketMoved,
        params:       { type: 'out' }
      },
    ]
    config[:metric][:count][:backend] = backend

    config[:metric][:create_channels] = {
      name:    'create_channels',
      display: __('Creation Channels'),
      prio:    9000,
    }
    backend = [
      {
        name:         'phone_in',
        display:      __('Phone (in)'),
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
        display:      __('Phone (out)'),
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
        display:      __('Email (in)'),
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
        display:      __('Email (out)'),
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
        display:      __('Web (in)'),
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
        display:      __('Twitter (in)'),
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
        display:      __('Twitter (out)'),
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
      display: __('Communication'),
      prio:    7000,
    }
    backend = [
      {
        name:         'phone_in',
        display:      __('Phone (in)'),
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
        display:      __('Phone (out)'),
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
        display:      __('Email (in)'),
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
        display:      __('Email (out)'),
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
        display:      __('Web (in)'),
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
        display:      __('Twitter (in)'),
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
        display:      __('Twitter (out)'),
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
