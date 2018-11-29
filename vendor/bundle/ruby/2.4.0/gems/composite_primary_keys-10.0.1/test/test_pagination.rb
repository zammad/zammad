#require File.expand_path('../abstract_unit', __FILE__)
#require 'plugins/pagination'
#
#class TestPagination < ActiveSupport::TestCase
#  fixtures :reference_types, :reference_codes
#
#  include ActionController::Pagination
#  DEFAULT_PAGE_SIZE = 2
#
#  attr_accessor :params
#
#  CLASSES = {
#    :single => {
#      :class => ReferenceType,
#      :primary_keys => :reference_type_id,
#      :table => :reference_types,
#    },
#    :dual   => {
#      :class => ReferenceCode,
#      :primary_keys => [:reference_type_id, :reference_code],
#      :table => :reference_codes,
#    },
#  }
#
#  def setup
#    self.class.classes = CLASSES
#    @params = {}
#  end
#
#  def test_paginate_all
#    testing_with do
#      @object_pages, @objects = paginate @klass_info[:table], :per_page => DEFAULT_PAGE_SIZE
#      assert_equal 2, @objects.length, "Each page should have #{DEFAULT_PAGE_SIZE} items"
#    end
#  end
#end