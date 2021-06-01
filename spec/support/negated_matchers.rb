# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_include, :include
RSpec::Matchers.define_negated_matcher :not_eq, :eq
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error
