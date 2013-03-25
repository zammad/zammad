# hook into fixnum so we can say things like:
#  5.business_minutes.from_now
#  4.business_minutes.before(some_date_time)
class Fixnum
  include BusinessTime
  
  def business_minutes
    BusinessMinutes.new(self)
  end
  alias_method :business_minute, :business_minutes
end