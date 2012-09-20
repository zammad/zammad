class App.Ticket extends App.Model
  @configure 'Ticket', 'number', 'title', 'group_id', 'owner_id', 'customer_id', 'ticket_state_id', 'ticket_priority_id', 'article'
  @extend Spine.Model.Ajax
  @url: '/api/tickets'
  @configure_attributes = [
      { name: 'number',                display: '#',        tag: 'input',    type: 'text', limit: 100, null: true, read_only: true },
      { name: 'customer_id',           display: 'Customer', tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8', autocapitalize: false, help: 'Select the customer of the Ticket or create one.', link: '<a href="" class="customer_new">&raquo;</a>' },
      { name: 'group_id',              display: 'Group',    tag: 'select',   multiple: false, limit: 100, null: false, class: 'span8', relation: 'Group', },
      { name: 'owner_id',              display: 'Owner',    tag: 'select',   multiple: false, limit: 100, null: true, class: 'span8', relation: 'User', },
      { name: 'title',                 display: 'Title',    tag: 'input',    type: 'text', limit: 100, null: false, class: 'span8',  },
      { name: 'ticket_state_id',       display: 'State',    tag: 'select',   multiple: false, null: false, relation: 'TicketState', default: 'new', class: 'medium' },
      { name: 'ticket_priority_id',    display: 'Priority', tag: 'select',   multiple: false, null: false, relation: 'TicketPriority', default: '2 normal', class: 'medium' },
      { name: 'created_at',            display: 'Created',  tag: 'time', },
      { name: 'last_contact',          display: 'Last contact',            tag: 'time', null: true },
      { name: 'last_contact_agent',    display: 'Last contact (Agent)',    tag: 'time', null: true },
      { name: 'last_contact_customer', display: 'Last contact (Customer)', tag: 'time', null: true },
      { name: 'first_response',        display: 'First response',          tag: 'time', null: true },
      { name: 'close_time',            display: 'Close time',              tag: 'time', null: true },
    ]