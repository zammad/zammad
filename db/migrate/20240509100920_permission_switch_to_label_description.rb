# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PermissionSwitchToLabelDescription < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_database
    change_wording
  end

  private

  def migrate_database
    rename_column :permissions, :note, :description
    add_column    :permissions, :label, :string, limit: 255

    Permission.reset_column_information
  end

  def change_wording
    new_permission_wording.each_with_index do |(permission_name, new_values), index|
      change_single_permission_wording(permission_name, new_values, index)
    end
  end

  def change_single_permission_wording(permission_name, new_values, index)
    permission = Permission.find_by(name: permission_name)
    return if permission.nil?

    permission.label = new_values[:label]
    permission.description = new_values[:description]
    permission.preferences.delete :translations
    permission.preferences[:prio] = 1_000 + (index * 10)
    permission.save!
  end

  def new_permission_wording
    {
      'admin'                                      => { label: 'Admin interface', description: 'Configure your system.' },
      'admin.user'                                 => { label: 'Users', description: 'Manage all users of your system.' },
      'admin.group'                                => { label: 'Groups', description: 'Manage groups of your system.' },
      'admin.role'                                 => { label: 'Roles', description: 'Manage roles of your system.' },
      'admin.organization'                         => { label: 'Organizations', description: 'Manage all organizations of your system.' },
      'admin.overview'                             => { label: 'Overviews', description: 'Manage ticket overviews of your system.' },
      'admin.text_module'                          => { label: 'Text modules', description: 'Manage text modules of your system.' },
      'admin.macro'                                => { label: 'Macros', description: 'Manage ticket macros of your system.' },
      'admin.template'                             => { label: 'Templates', description: 'Manage ticket templates of your system.' },
      'admin.tag'                                  => { label: 'Tags', description: 'Manage ticket tags of your system.' },
      'admin.calendar'                             => { label: 'Calendars', description: 'Manage calendars of your system.' },
      'admin.sla'                                  => { label: 'SLAs', description: 'Manage Service Level Agreements of your system.' },
      'admin.trigger'                              => { label: 'Trigger', description: 'Manage triggers of your system.' },
      'admin.public_links'                         => { label: 'Public Links', description: 'Manage public links of your system.' },
      'admin.webhook'                              => { label: 'Webhook', description: 'Manage webhooks of your system.' },
      'admin.scheduler'                            => { label: 'Scheduler', description: 'Manage schedulers of your system.' },
      'admin.report_profile'                       => { label: 'Report Profiles', description: 'Manage report profiles of your system.' },
      'admin.time_accounting'                      => { label: 'Time Accounting', description: 'Manage time accounting settings of your system.' },
      'admin.knowledge_base'                       => { label: 'Knowledge Base', description: 'Create and set up Knowledge Base.' },
      'admin.channel_web'                          => { label: 'Web', description: 'Manage web channel of your system.' },
      'admin.channel_formular'                     => { label: 'Form', description: 'Manage form channel of your system.' },
      'admin.channel_email'                        => { label: 'Email', description: 'Manage email channel of your system.' },
      'admin.channel_sms'                          => { label: 'SMS', description: 'Manage SMS channel of your system.' },
      'admin.channel_chat'                         => { label: 'Chat', description: 'Manage chat channel of your system.' },
      'admin.channel_google'                       => { label: 'Google', description: 'Manage Google mail channel of your system.' },
      'admin.channel_microsoft365'                 => { label: 'Microsoft 365', description: 'Manage Microsoft 365 mail channel of your system.' },
      'admin.channel_twitter'                      => { label: 'Twitter', description: 'Manage Twitter channel of your system.' },
      'admin.channel_facebook'                     => { label: 'Facebook', description: 'Manage Facebook channel of your system.' },
      'admin.channel_telegram'                     => { label: 'Telegram', description: 'Manage Telegram channel of your system.' },
      'admin.channel_whatsapp'                     => { label: 'WhatsApp', description: 'Manage WhatsApp channel of your system.' },
      'admin.branding'                             => { label: 'Branding', description: 'Manage branding settings of your system.' },
      'admin.setting_system'                       => { label: 'System', description: 'Manage core system settings.' },
      'admin.security'                             => { label: 'Security', description: 'Manage security settings of your system.' },
      'admin.ticket'                               => { label: 'Ticket', description: 'Manage ticket settings of your system.' },
      'admin.integration'                          => { label: 'Integrations', description: 'Manage integrations of your system.' },
      'admin.api'                                  => { label: 'API', description: 'Manage API of your system.' },
      'admin.object'                               => { label: 'Objects', description: 'Manage object attributes of your system.' },
      'admin.ticket_state'                         => { label: 'Ticket States', description: 'Manage ticket states of your system.' },
      'admin.ticket_priority'                      => { label: 'Ticket Priorities', description: 'Manage ticket priorities of your system.' },
      'admin.core_workflow'                        => { label: 'Core Workflows', description: 'Manage core workflows of your system.' },
      'admin.translation'                          => { label: 'Translations', description: 'Manage translations of your system.' },
      'admin.data_privacy'                         => { label: 'Data Privacy', description: 'Delete existing data of your system.' },
      'admin.maintenance'                          => { label: 'Maintenance', description: 'Manage maintenance mode of your system.' },
      'admin.monitoring'                           => { label: 'Monitoring', description: 'Manage monitoring of your system.' },
      'admin.package'                              => { label: 'Packages', description: 'Manage packages of your system.' },
      'admin.session'                              => { label: 'Sessions', description: 'Manage active user sessions of your system.' },
      'admin.system_report'                        => { label: 'System Report', description: 'Manage system report of your system.' },

      'chat'                                       => { label: 'Chat', description: 'Access to the chat interface.' },
      'chat.agent'                                 => { label: 'Agent chat', description: 'Access the agent chat features.' },

      'cti'                                        => { label: 'Phone', description: 'Access to the phone interface.' },
      'cti.agent'                                  => { label: 'Agent phone', description: 'Access the agent phone features.' },

      'knowledge_base'                             => { label: 'Knowledge Base', description: 'Access to the knowledge base interface.' },
      'knowledge_base.editor'                      => { label: 'Knowledge Base Editor', description: 'Access the knowledge base editor features.' },
      'knowledge_base.reader'                      => { label: 'Knowledge Base Reader', description: 'Access the knowledge base reader features.' },

      'report'                                     => { label: 'Report', description: 'Access to the report interface.' },

      'ticket'                                     => { label: 'Ticket', description: 'Access to the ticket interface.' },
      'ticket.agent'                               => { label: 'Agent tickets', description: 'Access the tickets as agent based on group access.' },
      'ticket.customer'                            => { label: 'Customer tickets', description: 'Access tickets as customer.' },

      'user_preferences'                           => { label: 'Profile settings', description: 'Manage personal settings.' },
      'user_preferences.appearance'                => { label: 'Appearance', description: 'Manage personal appearance settings.' },
      'user_preferences.language'                  => { label: 'Language', description: 'Manage personal language settings.' },
      'user_preferences.avatar'                    => { label: 'Avatar', description: 'Manage personal avatar settings.' },
      'user_preferences.out_of_office'             => { label: 'Out of Office', description: 'Manage personal out of office settings.' },
      'user_preferences.password'                  => { label: 'Password', description: 'Change personal account password.' },
      'user_preferences.two_factor_authentication' => { label: 'Two-factor Authentication', description: 'Manage personal two-factor authentication methods.' },
      'user_preferences.device'                    => { label: 'Devices', description: 'Manage personal devices and sessions.' },
      'user_preferences.access_token'              => { label: 'Token Access', description: 'Manage personal API tokens.' },
      'user_preferences.linked_accounts'           => { label: 'Linked Accounts', description: 'Manage personal linked accounts.' },
      'user_preferences.notifications'             => { label: 'Notifications', description: 'Manage personal notifications settings.' },
      'user_preferences.overview_sorting'          => { label: 'Overviews', description: 'Manage personal overviews.' },
      'user_preferences.calendar'                  => { label: 'Calendar', description: 'Manage personal calendar.' },
    }
  end
end
