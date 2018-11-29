module Clearbit
  class Pending
    def pending?
      true
    end

    def queued?
      true
    end

    def inspect
      'Your request is pending - please try again in few seconds, or pass the :stream option as true.'
    end
  end
end
