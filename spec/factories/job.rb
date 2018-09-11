FactoryBot.define do
  factory :job do
    sequence(:name) { |n| "Test job #{n}"  }
    condition     { { 'ticket.state_id' => { 'operator' => 'is not', 'value' => 4 } } }
    perform       { { 'ticket.state_id' => { 'value' => 4 } } }
    active        true
    created_by_id 1
    updated_by_id 1
    timeplan      do
      { 'days' => { 'Mon' => true, 'Tue' => false, 'Wed' => false, 'Thu' => false, 'Fri' => false, 'Sat' => false, 'Sun' => false },
        'hours' =>
       { '0' => true,
         '1' => false,
         '2' => false,
         '3' => false,
         '4' => false,
         '5' => false,
         '6' => false,
         '7' => false,
         '8' => false,
         '9' => false,
         '10' => false,
         '11' => false,
         '12' => false,
         '13' => false,
         '14' => false,
         '15' => false,
         '16' => false,
         '17' => false,
         '18' => false,
         '19' => false,
         '20' => false,
         '21' => false,
         '22' => false,
         '23' => false },
        'minutes' => { '0' => true, '10' => false, '20' => false, '30' => false, '40' => false, '50' => false } }
    end
  end
end
