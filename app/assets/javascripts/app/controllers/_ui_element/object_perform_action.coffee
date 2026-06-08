# coffeelint: disable=camel_case_classes
class App.UiElement.object_perform_action extends App.UiElement.ApplicationAction
  @defaults: (attribute, params = {}) ->
    groups =
      ticket:
        name: __('Ticket')
        model: 'Ticket'
        model_show: ['Ticket']
      article:
        name: __('Article')
        model: if attribute.article_body_cc_only then 'TicketArticle' else 'Article'
        model_show: ['Ticket']
      user:
        name: __('User')
        model: 'User'
        model_show: ['User']
      organization:
        name: __('Organization')
        model: 'Organization'
        model_show: ['Organization']

    if attribute.notification
      groups.notification =
        name: __('Notification')
        model: 'Notification'
        model_show: ['Ticket']

    if attribute.ai_agent
      groups.ai =
        name: __('AI')
        model: 'AI'
        model_show: ['Ticket']

    if attribute.object_name is undefined
      attribute.object_name = params.object or 'Ticket'

    defaults = []

    switch attribute.object_name
      when 'Ticket' then defaults.push 'ticket.state_id'
      when 'User' then defaults.push 'user.active'
      when 'Organization' then defaults.push 'organization.active'

    for key, data of groups
      continue if _.contains(data.model_show, attribute.object_name)
      delete groups[key]

    # merge config
    elements = {}
    for groupKey, groupMeta of groups
      if !groupMeta.model || !App[groupMeta.model]
        switch groupKey
          when 'notification'
            elements["#{groupKey}.email"] = { name: 'email', display: __('Email') }
            elements["#{groupKey}.sms"] = { name: 'sms', display: __('SMS') }
            elements["#{groupKey}.webhook"] = { name: 'webhook', display: __('Webhook') }
          when 'article'
            elements["#{groupKey}.note"] = { name: 'note', display: __('Note') }
          when 'ai'
            elements["#{groupKey}.ai_agent"] = { name: 'ai_agent', display: __('AI Agent') }
      else

        for row in App[groupMeta.model].configure_attributes

          # Prohibit the change of restricted attributes (i.e. uniques).
          continue if row.no_perform_changes

          # ignore all article attributes except body and cc
          if attribute.article_body_cc_only
            if groupMeta.model is 'TicketArticle'
              if row.name isnt 'body' and row.name isnt 'cc'
                continue

          # ignore all date and datetime attributes
          if attribute.no_dates
            if row.tag is 'date' || row.tag is 'datetime'
              continue

          # ignore passwords and relations
          if row.type isnt 'password' && row.name.substr(row.name.length-4,4) isnt '_ids'

            # ignore readonly attributes
            if !row.readonly
              config = _.clone(row)

              config.objectName    = groupMeta.model
              config.attributeName = config.name

              # disable uploads in richtext attributes
              if attribute.no_richtext_uploads
                if config.tag is 'richtext'
                  config.upload = false

              switch config.tag
                when 'date'
                  config.operator = ['static', 'relative']
                when 'datetime'
                  config.operator = ['static', 'relative']
                when 'tag'
                  config.operator = ['add', 'remove']

              elements["#{groupKey}.#{config.name}"] = config

    # Add ticket delete actions:
    #   - Delete immediately
    #   - Add a data privacy deletion task
    if attribute.object_name is 'Ticket' and (attribute.ticket_delete or attribute.data_privacy_deletion_task)
      availableActions = {}

      if attribute.ticket_delete
        availableActions.delete = __('Delete immediately')

      if attribute.data_privacy_deletion_task
        availableActions.data_privacy_deletion_task = __('Add a data privacy deletion task')

      elements['ticket.action'] =
        name: 'action'
        display: __('Action')
        tag: 'select'
        null: false
        translate: true
        options: availableActions
        alerts:
          delete: __('All affected tickets will be deleted immediately when this job is run, without a history entry. There is no rollback of this deletion possible.')
          data_privacy_deletion_task: __('All affected tickets will be scheduled for deletion when this job is run. Once the data privacy task is executed, tickets will be deleted and a history entry preserved. There is no rollback of this deletion possible.')

    # Add data privacy deletion task action for the user object.
    if attribute.object_name is 'User' and attribute.data_privacy_deletion_task
      elements['user.action'] =
        name: 'action'
        display: __('Action')
        tag: 'select'
        null: false
        translate: true
        options:
          data_privacy_deletion_task: __('Add a data privacy deletion task')
        alerts:
          data_privacy_deletion_task: __('All affected users and their customer tickets will be scheduled for deletion when this job is run. Once the data privacy task is executed, users and tickets will be deleted and a history entry preserved. There is no rollback of this deletion possible.')

    # add sender type selection as a ticket attribute
    if attribute.object_name is 'Ticket' and attribute.sender_type
      elements['ticket.formSenderType'] =
        name: 'formSenderType'
        display: __('Sender Type')
        tag: 'select'
        null: false
        translate: true
        options: [
          { value: 'phone-in', name: __('Inbound Call') },
          { value: 'phone-out', name: __('Outbound Call') },
          { value: 'email-out', name: __('Email') },
        ]

    if attribute.object_name is 'Ticket'
      elements['ticket.subscribe'] =
        name: 'subscribe'
        display: __('Subscribe')
        tag: 'select'
        null: false
        translate: true
        permission: ['ticket.agent']
        relation: 'User'
        relation_condition: {roles: 'Agent'}

      elements['ticket.unsubscribe'] =
        name: 'unsubscribe'
        display: __('Unsubscribe')
        tag: 'select'
        null: true
        translate: true
        permission: ['ticket.agent']
        relation: 'User'
        relation_condition: {roles: 'Agent'}

    [defaults, groups, elements]
