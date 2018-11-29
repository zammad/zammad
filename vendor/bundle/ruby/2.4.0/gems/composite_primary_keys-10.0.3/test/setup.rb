# setup_db.rb
require 'dbi'

# Run "createdb cpk_test" first

teacher_to_school = %Q{
  create table teacher_to_school(
    schoolid varchar(8),
    teacherid varchar(8),
    datebegin date,
    teacherrole varchar(20),
    primary key (schoolid, teacherid)
  );

}

globe_teacher = %Q{
  create table globe_teacher(
    teacherid varchar(8) primary key,
    currentschoolid varchar(8),
    userid varchar(16)
  );

}

globe_school = %Q{
  create table globe_school(
    schoolid varchar(8) primary key,
    schoolname varchar(100) not null,
    city varchar(35) not null
  )

}

add_records = [
  "insert into globe_teacher values ('ZZGLOBEY', 'ZZGLOBE1',
'dberger');",
  "insert into globe_school values ('ZZCOUCAR', 'NCAR Foothills Lab',
'Boulder');",
  "insert into globe_school values ('ZZGLOBE1', 'The GLOBE Program',
'Boulder');",
  "insert into teacher_to_school values('ZZGLOBE1', 'ZZGLOBEY', '1-JUN-2010', 'GLOBE OFFICE');",
  "insert into teacher_to_school values('ZZCOUCAR', 'ZZGLOBEY', '1-AUG-2010', 'GLOBE Teacher');"
]

DBI.connect('dbi:Pg:cpk_test', 'postgres') do |dbh|
  dbh.execute(teacher_to_school)
  dbh.execute(globe_teacher)
  dbh.execute(globe_school)
  add_records.each{ |sql| dbh.execute(sql) }
end 