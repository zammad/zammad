package org.jruby.ext.ref;

import java.lang.ref.WeakReference;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;

public class RubyWeakReference extends RubyObject {
  private WeakReference _ref;
  private static final String REFERENCED_OBJECT_ID_VARIABLE = "@referenced_object_id".intern();

  public RubyWeakReference(Ruby runtime, RubyClass klass) {
    super(runtime, klass);
  }
  
  public static final ObjectAllocator ALLOCATOR = new ObjectAllocator() {
    public IRubyObject allocate(Ruby runtime, RubyClass klass) {
      return new RubyWeakReference(runtime, klass);
    }
  };
  
  @JRubyMethod(name = "initialize", frame = true, visibility = Visibility.PRIVATE)
  public IRubyObject initialize(ThreadContext context, IRubyObject obj) {
    _ref = new WeakReference<IRubyObject>(obj);
    fastSetInstanceVariable(REFERENCED_OBJECT_ID_VARIABLE, obj.id());
    return context.getRuntime().getNil();
  }

  @JRubyMethod(name = "object")
  public IRubyObject object() {
    IRubyObject obj = (IRubyObject)_ref.get();
    if (obj != null) {
      return obj;
    } else {
      return getRuntime().getNil();
    }
  }
}
