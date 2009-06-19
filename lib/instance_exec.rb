# defines Object.instance_exec to permit call of a Proc with params
# in the context of an instance : instance.instance_exec( foo, bar, &proc )

unless defined? instance_exec # 1.8.7, 1.9
  class Proc #:nodoc:
    # defines an UnboundMethod, and binds it to object
    def bind(object)
      block, time = self, Time.now
      (class << object; self end).class_eval do
        method_name = "__bind_#{time.to_i}_#{time.usec}"
        define_method(method_name, &block)
        method = instance_method(method_name)
        remove_method(method_name)
        method
      end.bind(object)
    end
  end

  class Object
    def instance_exec(*arguments, &block)
      block.bind(self)[*arguments]
    end
  end
end
