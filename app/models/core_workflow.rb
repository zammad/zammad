# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow < ApplicationModel
  include ChecksClientNotification
  include ChecksCoreWorkflow
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include CoreWorkflow::Assets
  include CoreWorkflow::Search

  core_workflow_screens 'create', 'edit'

  default_scope { order(:priority, :id) }
  scope :active, -> { where(active: true) }
  scope :changeable, -> { where(changeable: true) }
  scope :object, ->(object) { where(object: [object, nil]) }

  store :preferences
  store :condition_saved
  store :condition_selected
  store :perform

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.classes
    Models.all.keys.select { |m| m.included_modules.include?(ChecksCoreWorkflow) }
  end

  def self.config
    classes.each_with_object({ configuration: {}, execution: {} }) do |config_class, result|
      if config_class.try(:core_workflow_screens).present?
        result[:execution][config_class.to_s] = config_class.try(:core_workflow_screens)
      end
      if config_class.try(:core_workflow_admin_screens).present?
        result[:configuration][config_class.to_s] = config_class.try(:core_workflow_admin_screens)
      end
    end
  end

=begin

Runs the core workflow engine based on the current state of the object.

  perform_result = CoreWorkflow.perform(payload: {
                                          'event'      => 'core_workflow',
                                          'request_id' => 'ChecksCoreWorkflow.validate_workflows',
                                          'class_name' => 'Ticket',
                                          'screen'     => 'edit',
                                          'params'     => Ticket.first.attributes,
                                        }, user: User.find(3), assets: false)

=end

  def self.perform(payload:, user:, assets: {}, assets_in_result: true, result: {}, form_updater: false)
    CoreWorkflow::Result.new(payload: payload, user: user, assets: assets, assets_in_result: assets_in_result, result: result, form_updater: form_updater).run
  rescue => e
    return {} if e.is_a?(ArgumentError)
    raise e if !Rails.env.production?

    Rails.logger.error 'Error performing Core Workflow engine.'
    Rails.logger.error e
    {}
  end

=begin

Checks if the object matches a specific condition.

Match saved data:

  CoreWorkflow.matches_selector?(
    id: Ticket.first.id,
    user: User.find_by(login: 'admin@example.com'),
    selector: { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => ['2'] } },
  )

Match payload selected data:

  CoreWorkflow.matches_selector?(
    check: 'selected',
    user: User.find_by(login: 'admin@example.com'),
    params: {
      'group_id'    => '1',
      'owner_id'    => '',
      'state_id'    => '2',
      'priority_id' => '2',
      'article'     => {
        'body'            => '',
        'type'            => 'note',
        'internal'        => true,
        'form_id'         => 'd8416050-0987-4ae4-b36f-c488b3b9b333',
        'shared_draft_id' => '',
        'subtype'         => '',
        'in_reply_to'     => '',
        'to'              => '',
        'cc'              => '',
        'subject'         => ''
      },
    },
    selector: { 'ticket.state_id'=>{ 'operator' => 'is', 'value' => ['2'] } },
  )

=end

  def self.matches_selector?(user:, selector:, id: nil, class_name: 'Ticket', params: {}, screen: 'edit', request_id: 'ChecksCoreWorkflow.validate_workflows', event: 'core_workflow', check: 'saved')
    if id.present?
      params['id'] = id
    end

    CoreWorkflow::Result.new(payload: {
                               'event'      => event,
                               'request_id' => request_id,
                               'class_name' => class_name,
                               'screen'     => screen,
                               'params'     => params,
                             }, user: user, assets: false, assets_in_result: false).matches_selector?(selector: selector, check: check)
  rescue => e
    return {} if e.is_a?(ArgumentError)
    raise e if !Rails.env.production?

    Rails.logger.error 'Error performing Core Workflow engine.'
    Rails.logger.error e
    false
  end
end
