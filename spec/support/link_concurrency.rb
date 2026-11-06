# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Two calls that link the same two objects, the second one started while the first one waits after it looked for an
#   existing link, as two requests could meet. Each call runs on a connection of its own, so the including group turns
#   off transactional tests, tags itself :ensure_threads_exited and removes the records it committed; the jobs they queued go here.
RSpec.shared_context 'with a link call that pauses after looking for an existing link' do
  let(:checked) { Queue.new }

  # The jobs the committed records queued, which a later example would find.
  around do |example|
    jobs  = Delayed::Job.maximum(:id).to_i
    locks = ActiveJobLock.maximum(:id).to_i
    example.run
  ensure
    Delayed::Job.where('id > ?', jobs).delete_all
    ActiveJobLock.where('id > ?', locks).delete_all
  end

  before do
    first = true
    allow(Link).to receive(:list).and_wrap_original do |original, *args, **kwargs|
      original.call(*args, **kwargs).tap do
        next if !first

        first = false
        checked.push(true)
        sleep 0.5
      end
    end
  end

  # @param first_call [Proc] the call that pauses
  # @param second_call [Proc] the call started meanwhile
  # @return [Array] what each call returned, or the refusal it raised
  def link_concurrently(first_call, second_call)
    first = link_thread(first_call)
    checked.pop(timeout: 10) || raise('The first call never looked for an existing link.')
    second = link_thread(second_call)

    [first.value, second.value]
  end

  def link_thread(call)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection { call.call }
    rescue Service::Link::Add::LinkedAlready => e
      e
    end
  end
end
