# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.TicketApproval extends App.Model
  @configure 'TicketApproval', 'id', 'ticket_id', 'status', 'message', 'priority', 'approver', 'approver_id', 'requester', 'requester_id', 'created_at', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets'
  @configure_attributes = [
    { name: 'id',                display: __('ID'),                tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'ticket_id',         display: __('Ticket'),           tag: 'input',    type: 'text', limit: 100, null: false, readonly: 1 },
    { name: 'status',            display: __('Status'),           tag: 'select',   multiple: false, limit: 100, null: false, options: { 'pending': __('Pending'), 'approved': __('Approved'), 'rejected': __('Rejected') }, default: 'pending' },
    { name: 'message',           display: __('Message'),          tag: 'textarea', rows: 4, limit: 500, null: true },
    { name: 'priority',          display: __('Priority'),         tag: 'select',   multiple: false, limit: 100, null: false, options: { 'low': __('Low'), 'normal': __('Normal'), 'high': __('High'), 'urgent': __('Urgent') }, default: 'normal' },
    { name: 'approver_id',       display: __('Approver'),         tag: 'select',   multiple: false, limit: 100, null: false, relation: 'User' },
    { name: 'approver',          display: __('Approver Name'),    tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'requester_id',      display: __('Requester'),        tag: 'select',   multiple: false, limit: 100, null: false, relation: 'User' },
    { name: 'requester',         display: __('Requester Name'),   tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'created_at',        display: __('Created'),          tag: 'datetime', null: true, readonly: 1 },
    { name: 'updated_at',        display: __('Updated'),          tag: 'datetime', null: true, readonly: 1 }
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = ['status', 'approver', 'requester', 'priority', 'created_at']

  @urlFor: (action, id) ->
    if action is 'create'
      return "#{@url}/#{@ticket_id}/approvals"
    else if action is 'update' or action is 'delete'
      return "#{@url}/#{@ticket_id}/approvals/#{id}"
    else if action is 'index'
      return "#{@url}/#{@ticket_id}/approvals"
    else
      return super

  @findByTicket: (ticket_id) ->
    @findAllByAttribute('ticket_id', ticket_id)

  @findPendingByTicket: (ticket_id) ->
    @findAllByAttribute('ticket_id', ticket_id).filter (approval) ->
      approval.status is 'pending'

  @findByApprover: (approver_id) ->
    @findAllByAttribute('approver_id', approver_id)

  @findPendingByApprover: (approver_id) ->
    @findAllByAttribute('approver_id', approver_id).filter (approval) ->
      approval.status is 'pending'

  isPending: ->
    @status is 'pending'

  isApproved: ->
    @status is 'approved'

  isRejected: ->
    @status is 'rejected'

  canApprove: ->
    @isPending() and App.User.current()?.id is @approver_id

  canReject: ->
    @isPending() and App.User.current()?.id is @approver_id

  canEdit: ->
    @isPending() and App.User.current()?.id is @requester_id

  priorityText: ->
    switch @priority
      when 'low' then __('Low')
      when 'normal' then __('Normal')
      when 'high' then __('High')
      when 'urgent' then __('Urgent')
      else @priority

  statusText: ->
    switch @status
      when 'pending' then __('Pending')
      when 'approved' then __('Approved')
      when 'rejected' then __('Rejected')
      else @status

  @refreshForTicket: (ticket_id, data) ->
    return if !ticket_id
    return if !data
    
    try
      # Remove existing approvals for this ticket
      existing = @findByTicket(ticket_id)
      for approval in existing
        approval.destroy()
      
      # Add new approvals from data
      if data.approvals and data.approvals.length > 0
        for approval_data in data.approvals
          # Check if approval already exists to avoid duplicates
          existing_approval = @find(approval_data.id)
          if existing_approval
            # Update existing approval without triggering refresh
            existing_approval.attr(approval_data)
          else
            # Create new approval without saving to server
            approval = new @(approval_data)
            approval.save = -> # Override save to prevent server call
            approval.save()
    catch e
      console.warn "Failed to refresh approvals for ticket #{ticket_id}:", e
