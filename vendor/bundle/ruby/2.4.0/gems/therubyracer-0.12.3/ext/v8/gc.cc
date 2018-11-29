#include "rr.h"

namespace rr {
  GC::Queue* queue;

  GC::Queue::Queue() : first(0), divider(0), last(0){
    first = new GC::Queue::Node(NULL);
    divider = first;
    last = first;
  }

  void GC::Queue::Enqueue(void* reference) {
    last->next = new Node(reference);
    last = last->next;
    while (first != divider) {
      Node* tmp = first;
      first = first->next;
      delete tmp;
    }
  }

  void* GC::Queue::Dequeue() {
    void* result = NULL;
    if (divider != last) {
      result = divider->next->value;
      divider = divider->next;
    }
    return result;
  }

  void GC::Finalize(void* phantom) {
    queue->Enqueue(phantom);
  }
  void GC::Drain(v8::GCType type, v8::GCCallbackFlags flags) {
    for(Phantom phantom = queue->Dequeue(); phantom.NotNull(); phantom = queue->Dequeue()) {
      phantom.destroy();
    }
  }
  void GC::Init() {
    queue = new GC::Queue();
    v8::V8::AddGCPrologueCallback(GC::Drain);
  }
}