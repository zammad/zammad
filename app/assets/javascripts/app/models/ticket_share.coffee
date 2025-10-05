# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.TicketShare extends App.Model
  @configure 'TicketShare', 'id', 'ticket_id', 'group_id', 'group_name', 'group', 'shared_by_id', 'shared_by_name', 'permissions', 'message', 'status', 'created_at', 'updated_at', 'expires_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/tickets'
  @configure_attributes = [
    { name: 'id',                display: __('ID'),                tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'ticket_id',         display: __('Ticket'),           tag: 'input',    type: 'text', limit: 100, null: false, readonly: 1 },
    { name: 'group_id',          display: __('Group'),            tag: 'select',   multiple: false, limit: 100, null: false, relation: 'Group' },
    { name: 'group_name',        display: __('Group Name'),       tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'shared_by_id',      display: __('Shared By'),        tag: 'select',   multiple: false, limit: 100, null: false, relation: 'User' },
    { name: 'shared_by_name',    display: __('Shared By Name'),   tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'permissions',       display: __('Permissions'),      tag: 'input',    type: 'text', limit: 100, null: true, readonly: 1 },
    { name: 'message',           display: __('Message'),          tag: 'textarea', rows: 4, limit: 500, null: true },
    { name: 'status',            display: __('Status'),           tag: 'select',   multiple: false, limit: 100, null: false, options: { 'active': __('Active'), 'revoked': __('Revoked') }, default: 'active' },
    { name: 'created_at',        display: __('Created'),          tag: 'datetime', null: true, readonly: 1 },
    { name: 'updated_at',        display: __('Updated'),          tag: 'datetime', null: true, readonly: 1 },
    { name: 'expires_at',        display: __('Expires'),          tag: 'datetime', null: true }
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = ['group_name', 'shared_by_name', 'status', 'created_at', 'expires_at']

  @urlFor: (action, id) ->
    if action is 'create'
      return "#{@url}/#{@ticket_id}/shares"
    else if action is 'update' or action is 'delete'
      return "#{@url}/#{@ticket_id}/shares/#{id}"
    else if action is 'index'
      return "#{@url}/#{@ticket_id}/shares"
    else
      return super

  @findByTicket: (ticket_id) ->
    @findAllByAttribute('ticket_id', ticket_id)

  @findActiveByTicket: (ticket_id) ->
    @findAllByAttribute('ticket_id', ticket_id).filter (share) ->
      share.status is 'active'

  isActive: ->
    @status is 'active'

  isExpired: ->
    return false unless @expires_at
    new Date(@expires_at) < new Date()

  canEdit: ->
    @isActive() and not @isExpired()

  permissionsText: ->
    if @permissions and @permissions.length > 0
      @permissions.join(', ')
    else
      __('Full Access')

  @refreshForTicket: (ticket_id, data) ->
    return if !ticket_id
    return if !data
    
    try
      # Remove existing shares for this ticket
      existing = @findByTicket(ticket_id)
      for share in existing
        share.destroy()
      
      # Add new shares from data
      if data.shares and data.shares.length > 0
        for share_data in data.shares
          # Check if share already exists to avoid duplicates
          existing_share = @find(share_data.id)
          if existing_share
            # Update existing share without triggering refresh
            existing_share.attr(share_data)
          else
            # Create new share without saving to server
            share = new @(share_data)
            share.save = -> # Override save to prevent server call
            share.save()
    catch e
      console.warn "Failed to refresh shares for ticket #{ticket_id}:", e
