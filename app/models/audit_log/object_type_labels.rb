# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module AuditLog::ObjectTypeLabels
  LABELS = {
    'AI::Agent'                    => __('AI agent'),
    'AI::ProviderConnection'       => __('AI provider'),
    'AI::TextTool'                 => __('Writing Assistant Tool'),
    'CoreWorkflow'                 => __('Core workflow'),
    'Job'                          => __('Scheduler'),
    'KnowledgeBase::Locale'        => __('Knowledge Base language'),
    'LdapSource'                   => __('LDAP'),
    'Permission'                   => __('Permission'),
    'PGPKey'                       => __('PGP'),
    'Setting'                      => __('Setting'),
    'Sla'                          => __('SLA'),
    'SMIMECertificate'             => __('S/MIME'),
    'SSLCertificate'               => __('SSL'),
    'TextModule'                   => __('Text module'),
    'Ticket::TimeAccounting::Type' => __('Time accounting type'),
    'User::TwoFactorPreference'    => __('Two-factor authentication'),
  }.freeze

  # Returns the label for a stored auditable_type (a model class name, e.g. from
  # self.class.name). Falls back to a titleized name - the frontend looks the label up in the
  # translation catalog, so the fallback must match the existing catalog keys. titleize is not
  # acronym-aware (e.g. "Ssl Certificate"), so acronym class names are covered by the map above.
  def label_for(class_name)
    LABELS[class_name.to_s] || class_name.to_s.split('::').map(&:titleize).join(' ')
  end
  module_function :label_for
end
