RSpec.shared_examples 'TicketEnqueuesTicketUserTicketCounterJob', type: :job do
  subject { create(described_class.name.underscore) }

  let(:customer) { create('customer') }

  it 'enqueues a job for the customer' do
    subject.customer = customer
    expect { subject.save }.to have_enqueued_job(TicketUserTicketCounterJob)
  end
end
