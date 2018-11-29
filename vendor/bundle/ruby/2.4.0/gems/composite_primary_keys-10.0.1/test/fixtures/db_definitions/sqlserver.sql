USE [composite_primary_keys_unittest];

CREATE TABLE topics (
    id          [int] IDENTITY(1000,1) NOT NULL,  
    name        [varchar](50) default NULL,  
    feed_size   [int] default NULL
);

CREATE TABLE topic_sources (
    topic_id    [int] NOT NULL,
    platform    [varchar](50) NOT NULL,
    keywords    [varchar](50) default NULL,
);

CREATE TABLE reference_types (
    reference_type_id [int] IDENTITY(1000,1) NOT NULL,
    type_label        [varchar](50) NULL,
    abbreviation      [varchar](50) NULL,
    description       [varchar](50) NULL
);

CREATE TABLE reference_codes (
    reference_type_id [int],
    reference_code    [int],
    code_label        [varchar](50) NULL,
    abbreviation      [varchar](50) NULL,
    description       [varchar](50) NULL
);

CREATE TABLE products (
    id   [int] IDENTITY(1000,1) NOT NULL,
    name [varchar](50) NULL
);

CREATE TABLE tariffs (
    [tariff_id]  [int],
    [start_date] [date],
    [amount]     [int] NULL,
    [created_at] [datetimeoffset](7) NOT NULL,
    [updated_at] [datetimeoffset](7) NOT NULL
    CONSTRAINT [tariffs_pk] PRIMARY KEY
        ( [tariff_id], [start_date] )
);

CREATE TABLE product_tariffs (
    [product_id]        [int],
    [tariff_id]         [int],
    [tariff_start_date] [date]
    CONSTRAINT [product_tariffs_pk] PRIMARY KEY
        ( [product_id], [tariff_id], [tariff_start_date] )
);

CREATE TABLE suburbs (
    city_id   [int],
    suburb_id [int],
    name      varchar(50) not null,
    CONSTRAINT [suburbs_pk] PRIMARY KEY
        ( [city_id], [suburb_id] )
);

CREATE TABLE streets (
    id        [int] IDENTITY(1000,1) NOT NULL,
    city_id   [int]   NOT NULL,
    suburb_id [int]   NOT NULL,
    name        [varchar](50)      NOT NULL
);

CREATE TABLE users (
    id   [int] IDENTITY(1000,1) NOT NULL,
    name varchar(50) NOT NULL
);

CREATE TABLE articles (
    id   [int] IDENTITY(1000,1) NOT NULL,
    name varchar(50) NOT NULL
);

CREATE TABLE readings (
    id         [int] PRIMARY KEY,
    user_id    [int] NOT NULL,
    article_id [int] NOT NULL,
    rating     [int] NOT NULL
);

CREATE TABLE groups (
    id   [int] IDENTITY(1000,1) NOT NULL,
    name [varchar](50) NOT NULL
);

CREATE TABLE memberships (
    user_id  [int] NOT NULL,
    group_id [int] NOT NULL
    CONSTRAINT [memberships_pk] PRIMARY KEY 
        ( [user_id], [group_id] )
);

CREATE TABLE membership_statuses (
    id       [int] IDENTITY(1,1) NOT NULL,
    user_id  [int]   not null,
    group_id [int]   not null,
    status   varchar(50) not null
);

CREATE TABLE departments (
    department_id [int] NOT NULL,
    location_id   [int] NOT NULL
    CONSTRAINT [departments_pk] PRIMARY KEY
        ( [department_id], [location_id] )
);

CREATE TABLE employees (
    id            [int] IDENTITY(1000,1) NOT NULL,
    department_id [int] NULL,
    location_id   [int] NULL
);

CREATE TABLE comments (
    id          [int] IDENTITY(1000,1) PRIMARY KEY NOT NULL,
    person_id   [int] NULL,
    shown       [int] NULL,
    person_type varchar(100)      NULL,
    hack_id     [int] NULL
);

CREATE TABLE hacks (
    id   [int]  IDENTITY(1000,1) PRIMARY KEY NOT NULL,
    name [varchar](50) NOT NULL
);

CREATE TABLE restaurants (
    franchise_id [int] NOT NULL,
    store_id     [int] NOT NULL,
    name         [varchar](100),
    lock_version [int] DEFAULT 0
    CONSTRAINT [restaurants_pk] PRIMARY KEY CLUSTERED 
        ( [franchise_id], [store_id] )
);

CREATE TABLE restaurants_suburbs (
    franchise_id [int] NOT NULL,
    store_id     [int] NOT NULL,
    city_id      [int] NOT NULL,
    suburb_id    [int] NOT NULL
);

CREATE TABLE dorms (
    id [int] IDENTITY(1000,1) PRIMARY KEY NOT NULL
);

CREATE TABLE rooms (
    dorm_id [int] NOT NULL,
    room_id [int] NOT NULL,
    CONSTRAINT [rooms_pk] PRIMARY KEY CLUSTERED 
        ( [dorm_id], [room_id] )
);

CREATE TABLE room_attributes (
    id   [int] IDENTITY(1000,1) PRIMARY KEY NOT NULL,
    name [varchar](50)
);

CREATE TABLE room_attribute_assignments (
    dorm_id           [int] NOT NULL,
    room_id           [int] NOT NULL,
    room_attribute_id [int] NOT NULL
);

CREATE TABLE students (
    id [int] IDENTITY(1000,1) PRIMARY KEY NOT NULL
);

CREATE TABLE room_assignments (
    student_id [int] NOT NULL,
    dorm_id    [int] NOT NULL,
    room_id    [int] NOT NULL
);

CREATE TABLE seats (
    flight_number [int] NOT NULL,
    seat          [int] NOT NULL,
    customer      [int]
    CONSTRAINT [seats_pk] PRIMARY KEY
        ( [flight_number], [seat] )
);

CREATE TABLE capitols (
    country varchar(450) NOT NULL,
    city varchar(450) NOT NULL
    CONSTRAINT [capitols_pk] PRIMARY KEY 
        ( [country], [city] )
);

CREATE TABLE products_restaurants (
    product_id   [int] NOT NULL,
    franchise_id [int] NOT NULL,
    store_id     [int] NOT NULL
);

CREATE TABLE employees_groups (
    employee_id [int] not null,
    group_id [int] not null
);

CREATE TABLE pk_called_ids (
    id                [int] IDENTITY(1000,1) NOT NULL,
    reference_code    [int]         not null,
    code_label        [varchar](50) default null,
    abbreviation      [varchar](50) default null,
    description       [varchar](50) default null
    CONSTRAINT [pk_called_ids_pk] PRIMARY KEY
        ( [id], [reference_code] )
);