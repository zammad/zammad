FactoryGirl.define do
  factory :ticket_article, class: Ticket::Article do
    from 'factory-customer-1@example.com'
    to 'factory-customer-1@example.com'
    subject 'factory article'
    message_id 'factory@id_com_1'
    body 'some message 123'
    internal false
    sender { Ticket::Article::Sender.find_by(name: 'Customer') }
    type { Ticket::Article::Type.find_by(name: 'email') }
    updated_by_id 1
    created_by_id 1
  end
end
