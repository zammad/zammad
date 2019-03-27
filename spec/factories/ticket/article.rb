FactoryBot.define do
  factory :'ticket/article', aliases: %i[ticket_article] do
    transient do
      type_name   { 'email' }
      sender_name { 'Customer' }
    end

    association :ticket, strategy: :create  # or else build(:ticket_article).save fails
    from          { 'factory-customer-1@example.com' }
    to            { 'factory-customer-1@example.com' }
    subject       { 'factory article' }
    message_id    { 'factory@id_com_1' }
    body          { 'some message 123' }
    internal      { false }
    sender        { Ticket::Article::Sender.find_by(name: sender_name) }
    type          { Ticket::Article::Type.find_by(name: type_name) }
    updated_by_id { 1 }
    created_by_id { 1 }

    factory :twitter_article do
      transient do
        type_name { 'twitter status' }
      end

      association :ticket, factory: :twitter_ticket
      body { Faker::Lorem.sentence }
    end
  end
end
