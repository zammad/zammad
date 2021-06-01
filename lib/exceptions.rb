# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Exceptions

  class NotAuthorized < StandardError; end

  class Forbidden < StandardError; end

  class UnprocessableEntity < StandardError; end

end
