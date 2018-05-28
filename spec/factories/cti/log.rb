FactoryBot.define do
  factory :cti_log, class: 'cti/log' do
    direction { %w[in out].sample }
    state     { %w[newCall answer hangup].sample }
    from      '4930609854180'
    to        '4930609811111'
    call_id   { (Cti::Log.pluck(:call_id).max || '0').next } # has SQL UNIQUE constraint
  end
end
