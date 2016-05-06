class UpdateTrigger2 < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    trigger = Trigger.find_by(name: 'auto reply (on new tickets)')
    return if !trigger
    trigger.condition = {
      'ticket.action' => {
        'operator' => 'is',
        'value' => 'create',
      },
      'ticket.state_id' => {
        'operator' => 'is not',
        'value' => Ticket::State.lookup(name: 'closed').id,
      },
      'article.type_id' => {
        'operator' => 'is',
        'value' => [
          Ticket::Article::Type.lookup(name: 'email').id,
          Ticket::Article::Type.lookup(name: 'phone').id,
          Ticket::Article::Type.lookup(name: 'web').id,
        ],
      },
      'article.sender_id' => {
        'operator' => 'is',
        'value' => Ticket::Article::Sender.lookup(name: 'Customer').id,
      },
    }
    trigger.save
  end

end
