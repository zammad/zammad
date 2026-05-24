# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MportsEngineeringBugIntake < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    create_group
    create_role
    create_custom_fields
    create_overview
  end

  private

  def create_group
    Group.create_if_not_exists(
      name:          'Engineering Bugs',
      note:          'Destination group for mPorts API-created engineering bug reports.',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def create_role
    role = Role.create_if_not_exists(
      name:              'mPorts Engineering Agent',
      note:              'Internal engineering/debug role for mPorts bug tickets. Can view/update engineering bug tickets, add internal notes, update custom fields. Cannot administer Zammad globally.',
      preferences:       {},
      default_at_signup: false,
      updated_by_id:     1,
      created_by_id:     1,
    )

    role.permission_grant('ticket.agent')
    role.permission_grant('user_preferences')
    role.permission_grant('knowledge_base.reader')

    group = Group.find_by(name: 'Engineering Bugs')
    return if group.blank?

    role.group_names_access_map = {
      group.name => %w[full],
    }
  end

  def create_custom_fields
    position = 1500

    # --- Core debugging fields ---

    add_input_field('mports_trace_id', 'mPorts Trace ID', position += 10)
    add_input_field('mports_request_id', 'mPorts Request ID', position += 10)
    add_input_field('mports_session_id', 'mPorts Session ID', position += 10)

    add_select_field('mports_environment', 'mPorts Environment', position += 10, {
      'local'         => 'Local',
      'staging'       => 'Staging',
      'production'    => 'Production',
      'agent_preview' => 'Agent Preview',
    })

    add_input_field('mports_tenant_id', 'mPorts Tenant ID', position += 10)
    add_input_field('mports_user_id', 'mPorts User ID', position += 10)
    add_input_field('mports_user_email', 'mPorts User Email', position += 10)

    add_select_field('mports_user_role', 'mPorts User Role', position += 10, {
      'public'   => 'Public',
      'buyer'    => 'Buyer',
      'seller'   => 'Seller',
      'admin'    => 'Admin',
      'internal' => 'Internal',
    })

    add_input_field('mports_page_url', 'mPorts Page URL', position += 10)

    add_select_field('mports_feature_area', 'mPorts Feature Area', position += 10, {
      'public_portal'     => 'Public Portal',
      'buyer_portal'      => 'Buyer Portal',
      'seller_portal'     => 'Seller Portal',
      'admin_portal'      => 'Admin Portal',
      'checkout'          => 'Checkout',
      'cart'              => 'Cart',
      'orders'            => 'Orders',
      'bas_buy_and_store' => 'Buy and Store (BAS)',
      'stored_inventory'  => 'Stored Inventory',
      'warehouse_release' => 'Warehouse Release',
      'bulk_upload'       => 'Bulk Upload',
      'shipping_docs'     => 'Shipping Docs',
      'inventory'         => 'Inventory',
      'warehouse_routing' => 'Warehouse Routing',
      'pricing'           => 'Pricing',
      'payments'          => 'Payments',
      'integrations'      => 'Integrations',
      'reporting'         => 'Reporting',
      'auth'              => 'Auth',
      'tenant_isolation'  => 'Tenant Isolation',
      'other'             => 'Other',
    })

    add_select_field('mports_severity', 'mPorts Severity', position += 10, {
      'blocker'  => 'Blocker',
      'major'    => 'Major',
      'minor'    => 'Minor',
      'cosmetic' => 'Cosmetic',
    })

    add_input_field('mports_build_sha', 'mPorts Build SHA', position += 10)
    add_input_field('mports_browser', 'mPorts Browser', position += 10)

    add_select_field('mports_ticket_type', 'mPorts Ticket Type', position += 10, {
      'support'             => 'Support',
      'bug'                 => 'Bug',
      'feature_request'     => 'Feature Request',
      'agent_task'          => 'Agent Task',
      'architecture_review' => 'Architecture Review',
    })

    # --- Agent workflow fields ---

    add_select_field('mports_agent_approved', 'mPorts Agent Approved', position += 10, {
      'false' => 'No',
      'true'  => 'Yes',
    })

    add_select_field('mports_agent_state', 'mPorts Agent State', position += 10, {
      'not_approved'     => 'Not Approved',
      'agent_approved'   => 'Agent Approved',
      'workspace_created' => 'Workspace Created',
      'builder_running'  => 'Builder Running',
      'builder_done'     => 'Builder Done',
      'reviewer_running' => 'Reviewer Running',
      'reviewer_passed'  => 'Reviewer Passed',
      'qa_running'       => 'QA Running',
      'qa_passed'        => 'QA Passed',
      'pr_ready'         => 'PR Ready',
      'human_review'     => 'Human Review',
      'blocked'          => 'Blocked',
      'closed'           => 'Closed',
    })

    add_input_field('mports_workspace_slot', 'mPorts Workspace Slot', position += 10)
    add_input_field('mports_branch_name', 'mPorts Branch Name', position += 10)
    add_input_field('mports_preview_url', 'mPorts Preview URL', position += 10)
    add_input_field('mports_pr_url', 'mPorts PR URL', position += 10)

    add_select_field('mports_reviewer_verdict', 'mPorts Reviewer Verdict', position += 10, {
      'none'  => 'None',
      'PASS'  => 'PASS',
      'WARN'  => 'WARN',
      'BLOCK' => 'BLOCK',
    })

    add_select_field('mports_qa_verdict', 'mPorts QA Verdict', position += 10, {
      'none'  => 'None',
      'PASS'  => 'PASS',
      'WARN'  => 'WARN',
      'BLOCK' => 'BLOCK',
    })

    # --- Business-context fields ---

    add_input_field('mports_order_id', 'mPorts Order ID', position += 10)
    add_input_field('mports_shipment_id', 'mPorts Shipment ID', position += 10)
    add_input_field('mports_po_id', 'mPorts PO ID', position += 10)
    add_input_field('mports_sku', 'mPorts SKU', position += 10)
    add_input_field('mports_warehouse_id', 'mPorts Warehouse ID', position += 10)
    add_input_field('mports_integration_name', 'mPorts Integration Name', position += 10)
    add_input_field('mports_integration_job_id', 'mPorts Integration Job ID', position += 10)
  end

  def create_overview
    engineering_role = Role.find_by(name: 'mPorts Engineering Agent')
    agent_role = Role.find_by(name: 'Agent')
    admin_role = Role.find_by(name: 'Admin')

    role_ids = [engineering_role&.id, agent_role&.id, admin_role&.id].compact

    group = Group.find_by(name: 'Engineering Bugs')
    return if group.blank?

    Overview.create_if_not_exists(
      name:      'Engineering Bugs',
      link:      'engineering_bugs',
      prio:      2000,
      role_ids:  role_ids,
      condition: {
        'ticket.group_id'            => {
          operator: 'is',
          value:    group.id.to_s,
        },
        'ticket.state_id'            => {
          operator: 'is not',
          value:    Ticket::State.find_by(name: 'closed')&.id&.to_s,
        },
      },
      order:     {
        by:        'updated_at',
        direction: 'DESC',
      },
      view:      {
        d:                 %w[number title state priority mports_severity mports_feature_area mports_environment mports_trace_id mports_agent_state mports_pr_url updated_at],
        s:                 %w[number title state mports_severity mports_agent_state updated_at],
        m:                 %w[number title state mports_severity updated_at],
        view_mode_default: 's',
      },
    )
  end

  def add_input_field(name, display, position)
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        name,
      display:     display,
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 500,
        null:      true,
      },
      editable:    true,
      internal:    false,
      active:      true,
      screens:     {
        create_middle: {
          'ticket.agent' => { null: true },
        },
        edit:          {
          'ticket.agent' => { null: true },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    position,
    )
  end

  def add_select_field(name, display, position, options)
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        name,
      display:     display,
      data_type:   'select',
      data_option: {
        default:    '',
        options:    options,
        nulloption: true,
        multiple:   false,
        null:       true,
        translate:  false,
      },
      editable:    true,
      internal:    false,
      active:      true,
      screens:     {
        create_middle: {
          'ticket.agent' => { null: true },
        },
        edit:          {
          'ticket.agent' => { null: true },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    position,
    )
  end
end
