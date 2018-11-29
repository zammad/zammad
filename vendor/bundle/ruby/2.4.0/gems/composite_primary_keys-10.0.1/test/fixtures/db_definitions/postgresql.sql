create table topics (
    id          serial not null,
    name        varchar(50) default null,  
    feed_size   int default null, 
    primary key (id)
);

create table topic_sources (
    topic_id int         not null,
    platform varchar(50) not null,
    keywords varchar(50) default null,
    primary key (topic_id,platform)
);

create table reference_types (
    reference_type_id serial not null,
    type_label        varchar(50) default null,
    abbreviation      varchar(50) default null,
    description       varchar(50) default null,
    primary key (reference_type_id)
);

create table reference_codes (
    reference_type_id int,
    reference_code    int         not null,
    code_label        varchar(50) default null,
    abbreviation      varchar(50) default null,
    description       varchar(50) default null,
    primary key (reference_type_id, reference_code)
);

create table products (
    id serial not null,
    name varchar(50) default null,
    primary key (id),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

create table tariffs (
    tariff_id  int  not null,
    start_date date not null,
    amount     int  default null,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    primary key (tariff_id, start_date)
);

create table product_tariffs (
    product_id        int  not null,
    tariff_id         int  not null,
    tariff_start_date date not null,
    primary key (product_id, tariff_id, tariff_start_date)
);

create table suburbs (
    city_id   int         not null,
    suburb_id int         not null,
    name      varchar(50) not null,
    primary key (city_id, suburb_id)
);

create table streets (
    id        serial      not null,
    city_id   int         not null,
    suburb_id int         not null,
    name      varchar(50) not null,
    primary key (id)
);

create table users (
    id   serial not null,
    name varchar(50) not null,
    primary key (id)
);

create table articles (
    id   serial not null,
    name varchar(50) not null,
    primary key (id)
);

create table readings (
    id         serial not null,
    user_id    int not null,
    article_id int not null,
    rating     int not null,
    primary key (id)
);

create table groups (
    id   serial not null,
    name varchar(50) not null,
    primary key (id)
);

create table memberships (
    user_id  int not null,
    group_id int not null,
    primary key (user_id, group_id)
);

create table membership_statuses (
    id       serial not null,
    user_id  int         not null,
    group_id int         not null,
    status   varchar(50) not null,
    primary key (id)
);

create table departments (
    department_id int not null,
    location_id   int not null,
    primary key (department_id, location_id)
);

create table employees (
    id            serial not null,
    department_id int default null,
    location_id   int default null,
    primary key (id)
);

create table salaries (
    id          serial not null,
    employee_id int,
    location_id int,
    year        int not null,
    month       int not null,
    value       int default null,
    primary key (id)
);

create table comments (
    id          serial not null,
    person_id   int          default null,
    shown       int          default null,
    person_type varchar(100) default null,
    hack_id     int          default null,
    primary key (id)
);

create table hacks (
    id serial not null,
    name varchar(50) not null,
    primary key (id)
);

create table restaurants (
    franchise_id int not null,
    store_id     int not null,
    name         varchar(100),
    lock_version int default 0,
    primary key (franchise_id, store_id)
);

create table restaurants_suburbs (
    franchise_id int not null,
    store_id     int not null,
    city_id      int not null,
    suburb_id    int not null
);

create table dorms (
    id serial not null,
    primary key (id)
);

create table rooms (
    dorm_id int not null,
    room_id int not null,
    primary key (dorm_id, room_id)
);

create table room_attributes (
    id   serial not null,
    name varchar(50),
    primary key (id)
);

create table room_attribute_assignments (
    dorm_id           int not null,
    room_id           int not null,
    room_attribute_id int not null
);

create table students (
    id serial not null,
    primary key (id)
);

create table room_assignments (
    student_id int not null,
    dorm_id    int not null,
    room_id    int not null
);

create table seats (
  flight_number int not null,
  seat          int not null,
  customer      int,
  primary key (flight_number, seat)
);

create table capitols (
  country text not null,
  city text not null,
  primary key (country, city)
);

create table products_restaurants (
  product_id int not null,
  franchise_id int not null,
  store_id int not null
);

create table employees_groups (
  employee_id int not null,
  group_id int not null
);

create table pk_called_ids (
    id serial not null,
    reference_code    int         not null,
    code_label        varchar(50) default null,
    abbreviation      varchar(50) default null,
    description       varchar(50) default null,
    primary key (id, reference_code)
);
