# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'deprecation_toolkit/rspec'

DeprecationToolkit::Configuration.test_runner = :rspec
# DeprecationToolkit::Configuration.warnings_treated_as_deprecation = [ %r{deprecat}i ]
