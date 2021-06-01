# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class EmailHelper

=begin

get available driver

  result = EmailHelper.available_driver

returns

  {
    inbound: {
      imap: 'IMAP',
      pop3: 'POP3',
    },
    outbound: {
      smtp: 'SMTP - configure your own outgoing SMTP settings',
      sendmail: 'Local MTA (Sendmail/Postfix/Exim/...) - use server setup',
    },
  }

=end

  def self.available_driver
    if Setting.get('system_online_service')
      return {
        inbound:  {
          imap: 'IMAP',
          pop3: 'POP3',
        },
        outbound: {
          smtp: 'SMTP - configure your own outgoing SMTP settings',
        },
      }
    end
    {
      inbound:  {
        imap: 'IMAP',
        pop3: 'POP3',
      },
      outbound: {
        smtp:     'SMTP - configure your own outgoing SMTP settings',
        sendmail: 'Local MTA (Sendmail/Postfix/Exim/...) - use server setup',
      },
    }
  end

=begin

get mail parts

  user, domain = EmailHelper.parse_email('somebody@example.com')

returns

  [user, domain]

=end

  def self.parse_email(email)
    user   = nil
    domain = nil
    if email =~ %r{^(.+?)@(.+?)$}
      user   = $1
      domain = $2
    end
    [user, domain]
  end

=begin

get list of providers with inbound and outbound settings

  map = EmailHelper.provider(email, password)

returns

  {
    google: {
      domain: 'gmail.com|googlemail.com|gmail.de',
      inbound: {
        adapter: 'imap',
        options: {
          host: 'imap.gmail.com',
          port: 993,
          ssl: true,
          user: email,
          password: password,
        },
      },
      outbound: {
        adapter: 'smtp',
        options: {
          host: 'smtp.gmail.com',
          port: 25,
          start_tls: true,
          user: email,
          password: password,
        }
      },
    },
    ...
  }

=end

  def self.provider(email, password)
    # check domain based attributes
    {
      google_imap: {
        domain:   'gmail|googlemail|google',
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'imap.gmail.com',
            port:     993,
            ssl:      true,
            user:     email,
            password: password,
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      'smtp.gmail.com',
            port:      25,
            start_tls: true,
            user:      email,
            password:  password,
          }
        },
      },
      microsoft:   {
        domain:   'outlook.com|hotmail.com',
        inbound:  {
          adapter: 'imap',
          options: {
            host:     'imap-mail.outlook.com',
            port:     993,
            ssl:      true,
            user:     email,
            password: password,
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      'smtp-mail.outlook.com',
            port:      25,
            start_tls: true,
            user:      email,
            password:  password,
          }
        },
      },
      google_pop3: {
        domain:   'gmail|googlemail|google',
        inbound:  {
          adapter: 'pop3',
          options: {
            host:     'pop.gmail.com',
            port:     995,
            ssl:      true,
            user:     email,
            password: password,
          },
        },
        outbound: {
          adapter: 'smtp',
          options: {
            host:      'smtp.gmail.com',
            port:      25,
            start_tls: true,
            user:      email,
            password:  password,
          }
        },
      },
    }

  end

=begin

get possible inbound settings based on mx

  map = EmailHelper.provider_inbound_mx(user, email, password, mx_domains)

returns

  {
    adapter: 'imap',
    options: {
      host: mx_domains[0],
      port: 993,
      ssl: true,
      user: user,
      password: password,
    },
  },
  {
    adapter: 'imap',
    options: {
      host: mx_domains[0],
      port: 993,
      ssl: true,
      user: email,
      password: password,
    },
  },

=end

  def self.provider_inbound_mx(user, email, password, mx_domains)
    inbounds = []
    mx_domains.each do |domain|
      inbound = [
        {
          adapter: 'imap',
          options: {
            host:     domain,
            port:     993,
            ssl:      true,
            user:     user,
            password: password,
          },
        },
        {
          adapter: 'imap',
          options: {
            host:     domain,
            port:     993,
            ssl:      true,
            user:     email,
            password: password,
          },
        },
      ]
      inbounds.concat(inbound)
    end
    inbounds
  end

=begin

get possible inbound settings based on guess

  map = EmailHelper.provider_inbound_guess(user, email, password, domain)

returns

  {
    adapter: 'imap',
    options: {
      host: "mail.#{domain}",
      port: 993,
      ssl: true,
      user: user,
      password: password,
    },
  },
  {
    adapter: 'imap',
    options: {
      host: "mail.#{domain}",
      port: 993,
      ssl: true,
      user: email,
      password: password,
    },
  },
  ...

=end

  def self.provider_inbound_guess(user, email, password, domain)
    [
      {
        adapter: 'imap',
        options: {
          host:     "mail.#{domain}",
          port:     993,
          ssl:      true,
          user:     user,
          password: password,
        },
      },
      {
        adapter: 'imap',
        options: {
          host:     "mail.#{domain}",
          port:     993,
          ssl:      true,
          user:     email,
          password: password,
        },
      },
      {
        adapter: 'imap',
        options: {
          host:     "imap.#{domain}",
          port:     993,
          ssl:      true,
          user:     user,
          password: password,
        },
      },
      {
        adapter: 'imap',
        options: {
          host:     "imap.#{domain}",
          port:     993,
          ssl:      true,
          user:     email,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "mail.#{domain}",
          port:     995,
          ssl:      true,
          user:     user,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "mail.#{domain}",
          port:     995,
          ssl:      true,
          user:     email,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "pop.#{domain}",
          port:     995,
          ssl:      true,
          user:     user,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "pop.#{domain}",
          port:     995,
          ssl:      true,
          user:     email,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "pop3.#{domain}",
          port:     995,
          ssl:      true,
          user:     user,
          password: password,
        },
      },
      {
        adapter: 'pop3',
        options: {
          host:     "pop3.#{domain}",
          port:     995,
          ssl:      true,
          user:     email,
          password: password,
        },
      },
    ]

  end

=begin

get possible outbound settings based on mx

  map = EmailHelper.provider_outbound_mx(user, email, password, mx_domains)

returns

  {
    adapter: 'smtp',
    options: {
      host: domain,
      port: 25,
      start_tls: true,
      user: user,
      password: password,
    },
  },
  {
    adapter: 'smtp',
    options: {
      host: domain,
      port: 25,
      start_tls: true,
      user: email,
      password: password,
    },
  },

=end

  def self.provider_outbound_mx(user, email, password, mx_domains)
    outbounds = []
    mx_domains.each do |domain|
      outbound = [
        {
          adapter: 'smtp',
          options: {
            host:      domain,
            port:      25,
            start_tls: true,
            user:      user,
            password:  password,
          },
        },
        {
          adapter: 'smtp',
          options: {
            host:      domain,
            port:      25,
            start_tls: true,
            user:      email,
            password:  password,
          },
        },
        {
          adapter: 'smtp',
          options: {
            host:      domain,
            port:      465,
            start_tls: true,
            user:      user,
            password:  password,
          },
        },
        {
          adapter: 'smtp',
          options: {
            host:      domain,
            port:      465,
            start_tls: true,
            user:      email,
            password:  password,
          },
        },
        {
          adapter: 'smtp',
          options: {
            host:     domain,
            port:     587,
            user:     user,
            password: password,
          },
        },
        {
          adapter: 'smtp',
          options: {
            host:     domain,
            port:     587,
            user:     email,
            password: password,
          },
        },
      ]
      outbounds.concat(outbound)
    end
    outbounds
  end

=begin

get possible outbound settings based on guess

  map = EmailHelper.provider_outbound_guess(user, email, password, domain)

returns

  {
    adapter: 'imap',
    options: {
      host: "mail.#{domain}",
      port: 993,
      ssl: true,
      user: user,
      password: password,
    },
  },
  {
    adapter: 'imap',
    options: {
      host: "mail.#{domain}",
      port: 993,
      ssl: true,
      user: email,
      password: password,
    },
  },
  ...

=end

  def self.provider_outbound_guess(user, email, password, domain)
    [
      {
        adapter: 'smtp',
        options: {
          host:      "mail.#{domain}",
          port:      25,
          start_tls: true,
          user:      user,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "mail.#{domain}",
          port:      25,
          start_tls: true,
          user:      email,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "mail.#{domain}",
          port:      465,
          start_tls: true,
          user:      user,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "mail.#{domain}",
          port:      465,
          start_tls: true,
          user:      email,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "smtp.#{domain}",
          port:      25,
          start_tls: true,
          user:      user,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "smtp.#{domain}",
          port:      25,
          start_tls: true,
          user:      email,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "smtp.#{domain}",
          port:      465,
          start_tls: true,
          user:      user,
          password:  password,
        },
      },
      {
        adapter: 'smtp',
        options: {
          host:      "smtp.#{domain}",
          port:      465,
          start_tls: true,
          user:      email,
          password:  password,
        },
      },
    ]

  end

=begin

get dns mx records of domain

  mx_records = EmailHelper.mx_records('example.com')

returns

  ['mx1.example.com', 'mx2.example.com']

=end

  def self.mx_records(domain)
    mail_exchangers = mxers(domain)
    if mail_exchangers && mail_exchangers[0]
      Rails.logger.info "MX for #{domain}: #{mail_exchangers} - #{mail_exchangers[0][0]}"
    end
    mx_records = []
    if mail_exchangers && mail_exchangers[0] && mail_exchangers[0][0]
      mx_records.push mail_exchangers[0][0]
    end
    mx_records
  end

  def self.mxers(domain)
    begin
      mxs = Resolv::DNS.open do |dns|
        ress = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
        ress.map do |r|
          [r.exchange.to_s, IPSocket.getaddress(r.exchange.to_s), r.preference]
        end
      end
    rescue => e
      Rails.logger.error e
    end
    mxs
  end

end
