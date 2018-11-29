require 'spec_helper'

describe V8::C::Locker do
  it "can lock and unlock the VM" do
    V8::C::Locker::IsLocked().should be_falsey
    V8::C::Locker() do
      V8::C::Locker::IsLocked().should be_truthy
      V8::C::Unlocker() do
        V8::C::Locker::IsLocked().should be_falsey
      end
    end
    V8::C::Locker::IsLocked().should be_falsey
  end

  it "properly unlocks if an exception is thrown inside a lock block" do
    begin
      V8::C::Locker() do
        raise "boom!"
      end
    rescue
      V8::C::Locker::IsLocked().should be_falsey
    end
  end

  it "properly re-locks if an exception is thrown inside an un-lock block" do
    V8::C::Locker() do
      begin
        V8::C::Unlocker() do
          raise "boom!"
        end
      rescue
        V8::C::Locker::IsLocked().should be_truthy
      end
    end
  end
end
