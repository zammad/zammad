package org.jruby.ext.ref;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

/**
 * This library adds native Java support for weak and soft references.
 * 
 * @author Brian Durand
 */
public class ReferencesService implements BasicLibraryService {
  public boolean basicLoad(Ruby runtime) throws IOException {
    RubyModule refModule = runtime.getModule("Ref");
    RubyClass referenceClass = refModule.getClass("Reference");
    
    RubyClass rubyWeakReferenceClass = runtime.defineClassUnder("WeakReference", referenceClass, RubyWeakReference.ALLOCATOR, refModule);
    rubyWeakReferenceClass.defineAnnotatedMethods(RubyWeakReference.class);
    
    RubyClass rubySoftReferenceClass = runtime.defineClassUnder("SoftReference", referenceClass, RubySoftReference.ALLOCATOR, refModule);
    rubySoftReferenceClass.defineAnnotatedMethods(RubySoftReference.class);
    
    return true;
  }
}
