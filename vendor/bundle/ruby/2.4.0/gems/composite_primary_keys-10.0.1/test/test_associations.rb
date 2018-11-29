require File.expand_path('../abstract_unit', __FILE__)

class TestAssociations < ActiveSupport::TestCase
  fixtures :articles, :products, :tariffs, :product_tariffs, :suburbs, :streets, :restaurants,
           :dorms, :rooms, :room_attributes, :room_attribute_assignments, :students, :room_assignments, :users, :readings,
           :departments, :employees, :memberships, :membership_statuses

  def test_products
    assert_not_nil products(:first_product).product_tariffs
    assert_equal 2, products(:first_product).product_tariffs.length
    assert_not_nil products(:first_product).tariffs
    assert_equal 2, products(:first_product).tariffs.length
  end

  def test_product_tariffs
    assert_not_nil product_tariffs(:first_flat).product
    assert_not_nil product_tariffs(:first_flat).tariff
    assert_equal Product, product_tariffs(:first_flat).product.class
    assert_equal Tariff, product_tariffs(:first_flat).tariff.class
  end

  def test_tariffs
    assert_not_nil tariffs(:flat).product_tariffs
    assert_equal 1, tariffs(:flat).product_tariffs.length
    assert_not_nil tariffs(:flat).products
    assert_equal 1, tariffs(:flat).products.length
  end

  # Its not generating the instances of associated classes from the rows
  def test_find_includes
    # Old style
    products = Product.includes(:product_tariffs).all
    assert_equal(3, products.length)
    assert_equal(3, products.inject(0) {|sum, product| sum + product.product_tariffs.length})

    # New style
    products = Product.includes(:product_tariffs)
    assert_equal(3, products.length)
    assert_equal(3, products.inject(0) {|sum, product| sum + product.product_tariffs.length})
  end

  def test_find_includes_eager_loading
    product = products(:second_product)
    product_tarrif = product_tariffs(:second_free)

    # First get a legitimate product tarrif
    products = Product.includes(:product_tariffs).where('product_tariffs.product_id = ?', product.id).references(:product_tariffs)
    assert_equal(1, products.length)
    assert_equal(product, products.first)
    assert_equal([product_tarrif], products.first.product_tariffs)
  end

  def test_find_eager_loading_none
    product = products(:third_product)

    products = Product.includes(:product_tariffs).where(:id => product.id).references(:product_tariffs)
    assert_equal(1, products.length)
    assert_equal(product, products.first)
    assert_empty(products.first.product_tariffs)
  end

  def test_find_includes_tariffs
    # Old style
    tariffs = Tariff.includes(:product_tariffs)
    assert_equal(3, tariffs.length)
    assert_equal(3, tariffs.inject(0) {|sum, tariff| sum + tariff.product_tariffs.length})

    # New style
    tariffs = Tariff.includes(:product_tariffs)
    assert_equal(3, tariffs.length)
    assert_equal(3, tariffs.inject(0) {|sum, tariff| sum + tariff.product_tariffs.length})
  end

  def test_has_one_association_is_not_cached_to_where_it_returns_the_wrong_one
    engineering = departments(:engineering)
    engineering_head = engineering.head
    assert_equal(employees(:sarah), engineering_head)

    accounting = departments(:accounting)
    accounting_head = accounting.head
    assert_equal(employees(:steve), accounting_head)

    refute_equal accounting_head, engineering_head
  end

  def test_has_one_association_primary_key_and_foreign_key_are_present
    steve = employees(:steve)
    steve_salary = steve.create_one_salary(year: "2015", month: "1")

    jill = employees(:jill)
    jill_salary = jill.create_one_salary(year: "2015", month: "1")

    steve_salary.reload
    jill_salary.reload
    assert_equal(steve.id, steve_salary.employee_id)
    assert_equal(1, steve_salary.location_id)
    assert_equal(jill.id, jill_salary.employee_id)
    assert_equal(1, jill_salary.location_id)
  end

  def test_has_many_association_is_not_cached_to_where_it_returns_the_wrong_ones
    engineering = departments(:engineering)
    engineering_employees = engineering.employees

    accounting = departments(:accounting)
    accounting_employees = accounting.employees

    refute_equal accounting_employees, engineering_employees
  end

  def test_has_many_association_primary_key_and_foreign_key_are_present
    steve = employees(:steve)
    steve_salary = steve.salaries.create(year: 2015, month: 1)

    jill = employees(:jill)
    jill_salary = jill.salaries.create(year: 2015, month: 1)

    steve_salary.reload
    jill_salary.reload
    assert_equal(steve.id, steve_salary.employee_id)
    assert_equal(1, steve_salary.location_id)
    assert_equal(jill.id, jill_salary.employee_id)
    assert_equal(1, jill_salary.location_id)
  end

  def test_belongs_to_association_primary_key_and_foreign_key_are_present
    bogus_foreign_key = 2_500_000
    salary_01 = Salary.new(
      year: 2015,
      month: 1,
      employee_id: bogus_foreign_key,
      location_id: 1
    )
    employee_01 = salary_01.create_employee
    employee_01.reload

    assert_equal(salary_01.employee_id, employee_01.id, "Generated id used")
    assert_not_equal(bogus_foreign_key, employee_01.id, "Bogus value ignored")
    assert_equal(1, employee_01.location_id)
  end

  def test_find_includes_product_tariffs_product
    # Old style
    product_tariffs = ProductTariff.includes(:product)
    assert_not_nil(product_tariffs)
    assert_equal(3, product_tariffs.length)

    # New style
    product_tariffs = ProductTariff.includes(:product)
    assert_not_nil(product_tariffs)
    assert_equal(3, product_tariffs.length)
  end

  def test_find_includes_product_tariffs_tariff
    # Old style
    product_tariffs = ProductTariff.includes(:tariff)
    assert_equal(3, product_tariffs.length)

    # New style
    product_tariffs = ProductTariff.includes(:tariff)
    assert_equal(3, product_tariffs.length)
  end

  def test_has_many_through
    products = Product.includes(:tariffs)
    assert_equal(3, products.length)

    tarrifs_length = products.inject(0) {|sum, product| sum + product.tariffs.length}
    assert_equal(3, tarrifs_length)
  end

  def test_new_style_includes_with_conditions
    product_tariff = ProductTariff.includes(:tariff).where('tariffs.amount < 5').references(:tariffs).first
    assert_equal(0, product_tariff.tariff.amount)
  end

  def test_find_product_includes
    products = Product.includes(:product_tariffs => :tariff)
    assert_equal(3, products.length)

    product_tariffs_length = products.inject(0) {|sum, product| sum + product.product_tariffs.length}
    assert_equal(3, product_tariffs_length)
  end

  def test_find_tariffs_includes
    tariffs = Tariff.includes(:product_tariffs => :product)
    assert_equal(3, tariffs.length)

    product_tariffs_length = tariffs.inject(0) {|sum, tariff| sum + tariff.product_tariffs.length}
    assert_equal(3, product_tariffs_length)
  end

  def test_has_many_through_when_not_pre_loaded
    student = Student.first
    rooms = student.rooms
    assert_equal(1, rooms.size)
    assert_equal(1, rooms.first.dorm_id)
    assert_equal(1, rooms.first.room_id)
  end

  def test_has_many_through_when_through_association_is_composite
    dorm = Dorm.first
    assert_equal(3, dorm.rooms.length)
    assert_equal(1, dorm.rooms.first.room_attributes.length)
    assert_equal('type', dorm.rooms.first.room_attributes.first.name)
  end

  def test_associations_with_conditions
    suburb = Suburb.find([2, 1])
    assert_equal 2, suburb.streets.size

    suburb = Suburb.find([2, 1])
    assert_equal 1, suburb.first_streets.size

    suburb = Suburb.includes(:streets).find([2, 1])
    assert_equal 2, suburb.streets.size

    suburb = Suburb.includes(:first_streets).find([2, 1])
    assert_equal 1, suburb.first_streets.size
  end

  def test_composite_has_many_composites
    room = rooms(:branner_room_1)
    assert_equal(2, room.room_assignments.length)
    assert_equal(room_assignments(:jacksons_room), room.room_assignments[0])
    assert_equal(room_assignments(:bobs_room), room.room_assignments[1])
  end

  def test_composite_belongs_to_composite
    room_assignment = room_assignments(:jacksons_room)
    assert_equal(rooms(:branner_room_1), room_assignment.room)
  end

  def test_composite_belongs_to_changes
    room_assignment = room_assignments(:jacksons_room)
    room_assignment.room = rooms(:branner_room_2)
    # This was raising an error before:
    #   TypeError: [:dorm_id, :room_id] is not a symbol
    # changes returns HashWithIndifferentAccess
    assert_equal({"room_id"=>[1, 2]}, room_assignment.changes)

    steve = employees(:steve)
    steve.department = departments(:engineering)
    # It was returning this before:
    #   {"[:department_id, :location_id]"=>[nil, [2, 1]]}
    assert_equal({"department_id"=>[1, 2]}, steve.changes)
  end

  def test_composite_belongs_to__setting_to_nil
    room_assignment = room_assignments(:jacksons_room)
    # This was raising an error before:
    #   NoMethodError: undefined method `length' for nil:NilClass
    assert_nothing_raised { room_assignment.room = nil }
  end

  def test_has_one_with_composite
    # In this case a regular model has_one composite model
    department = departments(:engineering)
    assert_not_nil(department.head)
  end

  def test_has_many_build_simple_key
    user = users(:santiago)
    reading = user.readings.build
    assert_equal user.id, reading.user_id
    assert_equal user,    reading.user
  end

  def test_has_many_build__composite_key
    department = departments(:engineering)
    employee = department.employees.build
    assert_equal department.department_id, employee.department_id
    assert_equal department.location_id,   employee.location_id
    assert_equal department,               employee.department
  end

  def test_has_many_with_primary_key
    @membership = Membership.find([1, 1])
    assert_equal 2, @membership.readings.size
  end

  def test_has_many_with_composite_key
    # In this case a regular model (Dorm) has_many composite models (Rooms)
    dorm = dorms(:branner)
    assert_equal(3, dorm.rooms.length)
    assert_equal(1, dorm.rooms[0].room_id)
    assert_equal(2, dorm.rooms[1].room_id)
    assert_equal(3, dorm.rooms[2].room_id)
  end

  def test_joins_has_many_with_primary_key
    #@membership = Membership.find(:first, :joins => :readings, :conditions => { :readings => { :id => 1 } })
    @membership = Membership.joins(:readings).where(readings: { id: 1 }).first

    assert_equal [1, 1], @membership.id
  end

  def test_joins_has_one_with_primary_key
    @membership = Membership.joins(:readings).where(readings: { id: 2 }).first

    assert_equal [1, 1], @membership.id
  end

  def test_has_many_through_with_conditions_when_through_association_is_not_composite
    user = User.first
    assert_equal 1, user.articles.where("articles.name = ?", "Article One").size
  end

  def test_has_many_through_with_conditions_when_through_association_is_composite
    room = Room.first
    assert_equal 0, room.room_attributes.where("room_attributes.name != ?", "type").size
  end

  def test_has_many_through_on_custom_finder_when_through_association_is_composite_finder_when_through_association_is_not_composite
    user = User.first
    assert_equal(1, user.find_custom_articles.size)
  end

  def test_has_many_through_on_custom_finder_when_through_association_is_composite
    room = Room.first
    assert_equal(0, room.find_custom_room_attributes.size)
  end

  def test_has_many_with_primary_key_with_associations
    memberships = Membership.includes(:statuses).where("membership_statuses.status = ?", 'Active').references(:membership_statuses)
    assert_equal(2, memberships.length)
    assert_equal([1,1], memberships[0].id)
    assert_equal([3,2], memberships[1].id)
  end

  def test_limitable_reflections
    memberships = Membership.includes(:statuses).where("membership_statuses.status = ?", 'Active').references(:membership_statuses).limit(1)
    assert_equal(1, memberships.length)
    assert_equal([1,1], memberships[0].id)
  end

  def test_foreign_key_present_with_null_association_ids
    group = Group.new
    group.memberships.build
    associations = group.association(:memberships)
    assert_equal(false, associations.send('foreign_key_present?'))
  end

  def test_ids_equals_for_non_CPK_case
    article = Article.new
    article.reading_ids = Reading.pluck(:id)
    assert_equal article.reading_ids, Reading.pluck(:id)
  end
end
