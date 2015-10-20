class Report

  def self.config
    config = {}
    config[:metric] = {}

    config[:metric][:count] = {
      name: 'count',
      display: 'Ticket Count',
      default: true,
      prio: 10_000,
    }
    backend = [
      {
        name: 'created',
        display: 'Created',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'closed',
        display: 'Closed',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'backlog',
        display: 'Backlog',
        selected: true,
        dataDownload: false,
      },
      {
        name: 'first_solution',
        display: 'First Solution',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'reopen',
        display: 'Re-Open',
        selected: false,
        dataDownload: true,
      },
      {
        name: 'movedin',
        display: 'Moved in',
        selected: false,
        dataDownload: true,
      },
      {
        name: 'movedout',
        display: 'Moved out',
        selected: false,
        dataDownload: true,
      },
      {
        name: 'sla_in',
        display: 'SLA in',
        selected: false,
        dataDownload: true,
      },
      {
        name: 'sla_out',
        display: 'SLA out',
        selected: false,
        dataDownload: true,
      },
    ]
    config[:metric][:count][:backend] = backend

    config[:metric][:create_channels] = {
      name: 'create_channels',
      display: 'Create Channels',
      prio: 9000,
    }
    backend = [
      {
        name: 'phone_in',
        display: 'Phone (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'phone_out',
        display: 'Phone (out)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'email_in',
        display: 'Email (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'email_out',
        display: 'Email (out)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'web_in',
        display: 'Web (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'twitter_in',
        display: 'Twitter (in)',
        selected: true,
        dataDownload: true,
      },
    ]
    config[:metric][:create_channels][:backend] = backend

    config[:metric][:times] = {
      name: 'times',
      display: 'Times',
      prio: 8000,
    }
    backend = [
      {
        name: 'first_response_average',
        display: 'First Response average',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'first_response_max',
        display: 'First Response max',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'first_response_min',
        display: 'First Response min',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'solution_time_average',
        display: 'Solution Time average',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'solution_time_max',
        display: 'Solution Time max',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'solution_time_min',
        display: 'Solution Time min',
        selected: true,
        dataDownload: true,
      },
    ]
    config[:metric][:times][:backend] = backend

    config[:metric][:communication] = {
      name: 'communication',
      display: 'Communication',
      prio: 7000,
    }
    backend = [
      {
        name: 'phone_in',
        display: 'Phone (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'phone_out',
        display: 'Phone (out)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'email_in',
        display: 'Email (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'email_out',
        display: 'Email (out)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'web_in',
        display: 'Web (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'twitter_in',
        display: 'Twitter (in)',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'twitter_out',
        display: 'Twitter (out)',
        selected: true,
        dataDownload: true,
      },
    ]
    config[:metric][:communication][:backend] = backend

    config[:metric][:sla] = {
      name: 'sla',
      display: 'SLAs',
      prio: 6000,
    }
    backend = [
      {
        name: 'sla_out_1',
        display: 'SLA (out) - <1h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_out_2',
        display: 'SLA (out) - <2h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_out_4',
        display: 'SLA (out) - <4h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_out_8',
        display: 'SLA (out) - <8h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_in_1',
        display: 'SLA (in) - <1h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_in_2',
        display: 'SLA (in) - <2h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_in_4',
        display: 'SLA (in) - <4h',
        selected: true,
        dataDownload: true,
      },
      {
        name: 'sla_in_8',
        display: 'SLA (in) - <8h',
        selected: true,
        dataDownload: true,
      },
    ]
    config[:metric][:sla][:backend] = backend

    config[:metric].each {|metric_key, metric_value|
      metric_value[:backend].each {|metric_backend|
        metric_backend[:name] = "#{metric_key}::#{metric_backend[:name]}"
      }
    }

    config
  end

end
