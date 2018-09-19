FactoryBot.define do
  factory :ticket_time_accounting, class: Ticket::TimeAccounting do
    ticket_id { FactoryBot.create(:ticket).id }
    ticket_article_id { FactoryBot.create(:ticket_article).id }
    time_unit 200
    created_by_id 1
    created_at Time.zone.now
    updated_at Time.zone.now
  end
end
