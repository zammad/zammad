# assoc_test.rb

path = File.expand_path(File.join(File.basename(__FILE__), "..", "lib", "composite_primary_keys"))
puts path

require File.join(path)
require 'active_record'

$configuration = {
  :adapter  => 'postgresql',
  :database => 'cpk_test',
  :username => 'postgres'
}

ActiveRecord::Base.establish_connection($configuration) unless ActiveRecord::Base.connected?

module GlobePG
  class PGBase < ActiveRecord::Base
    self.abstract_class = true
   # establish_connection($configuration) unless connected?
  end
end

module GlobePG
  class TeacherToSchool < PGBase
    set_table_name 'teacher_to_school'
    self.primary_keys = ['teacherid', 'schoolid']

    belongs_to :globe_teacher, :foreign_key => 'teacherid'
    belongs_to :globe_school, :foreign_key => 'schoolid'
  end
end

module GlobePG
  class GlobeSchool < PGBase
    set_table_name 'globe_school'
    self.primary_key = 'schoolid'
    has_many :teacher_to_schools, :foreign_key => :schoolid
    has_many :globe_teachers, :through => :teacher_to_schools
  end
end

module GlobePG
  class GlobeTeacher < PGBase
    set_table_name 'globe_teacher'
    self.primary_key = 'teacherid'
    has_many :teacher_to_schools, :foreign_key => :teacherid
    has_many :globe_schools, :through => :teacher_to_schools
  end
end

teacher = GlobePG::GlobeTeacher.find_by_teacherid('ZZGLOBEY')
p teacher.globe_schools 