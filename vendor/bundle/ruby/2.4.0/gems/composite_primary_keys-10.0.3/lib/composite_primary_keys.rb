#--
# Copyright (c) 2006-2016 Nic Williams and Charlie Savage
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

unless defined?(ActiveRecord)
  require 'rubygems'
  gem 'activerecord', ['~>5.1.0', '>= 5.1.5']
  require 'active_record'
end

# AR files we override
require 'active_record/counter_cache'
require 'active_record/fixtures'
require 'active_record/model_schema'
require 'active_record/persistence'
require 'active_record/relation'
require 'active_record/sanitization'
require 'active_record/attribute_methods'
require 'active_record/autosave_association'

require 'active_record/associations/association'
require 'active_record/associations/association_scope'
require 'active_record/associations/has_many_association'
require 'active_record/associations/has_many_through_association'
require 'active_record/associations/join_dependency'
require 'active_record/associations/join_dependency/join_association'
require 'active_record/associations/preloader/association'
require 'active_record/associations/preloader/belongs_to'
require 'active_record/associations/singular_association'
require 'active_record/associations/collection_association'

require 'active_record/attribute_set/builder'
require 'active_record/attribute_methods/primary_key'
require 'active_record/attribute_methods/read'
require 'active_record/attribute_methods/write'
require 'active_record/locking/optimistic'
require 'active_record/nested_attributes'

require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_record/connection_adapters/postgresql/database_statements'

require 'active_record/relation/batches'
require 'active_record/relation/where_clause'
require 'active_record/relation/calculations'
require 'active_record/relation/finder_methods'
require 'active_record/relation/query_methods'

# CPK files
require 'composite_primary_keys/persistence'
require 'composite_primary_keys/base'
require 'composite_primary_keys/core'
require 'composite_primary_keys/composite_arrays'
require 'composite_primary_keys/composite_predicates'
require 'composite_primary_keys/fixtures'
require 'composite_primary_keys/relation'
require 'composite_primary_keys/sanitization'
require 'composite_primary_keys/attribute_set/builder'
require 'composite_primary_keys/attribute_methods'
require 'composite_primary_keys/autosave_association'
require 'composite_primary_keys/version'

require 'composite_primary_keys/associations/association'
require 'composite_primary_keys/associations/association_scope'
require 'composite_primary_keys/associations/has_many_association'
require 'composite_primary_keys/associations/has_many_through_association'
require 'composite_primary_keys/associations/join_dependency'
require 'composite_primary_keys/associations/join_dependency/join_association'
require 'composite_primary_keys/associations/preloader/association'
require 'composite_primary_keys/associations/preloader/belongs_to'
require 'composite_primary_keys/associations/collection_association'

require 'composite_primary_keys/attribute_methods/primary_key'
require 'composite_primary_keys/attribute_methods/read'
require 'composite_primary_keys/attribute_methods/write'
require 'composite_primary_keys/locking/optimistic'
require 'composite_primary_keys/nested_attributes'

require 'composite_primary_keys/connection_adapters/abstract_adapter'
require 'composite_primary_keys/connection_adapters/abstract_mysql_adapter'
require 'composite_primary_keys/connection_adapters/postgresql/database_statements'

require 'composite_primary_keys/relation/batches'
require 'composite_primary_keys/relation/where_clause'
require 'composite_primary_keys/relation/calculations'
require 'composite_primary_keys/relation/finder_methods'
require 'composite_primary_keys/relation/predicate_builder/association_query_handler'
require 'composite_primary_keys/relation/query_methods'

require 'composite_primary_keys/composite_relation'

require 'composite_primary_keys/arel/in'
require 'composite_primary_keys/arel/to_sql'
require 'composite_primary_keys/arel/sqlserver'
