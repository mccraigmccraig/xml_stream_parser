# defines Object.instance_exec to permit call of a Proc with params
# in the context of an instance : instance.instance_exec( foo, bar, &proc )
# taken from rails 2.2
#
class Object
  unless defined? instance_exec # 1.9
    module InstanceExecMethods #:nodoc:
      @mutex = Mutex.new
      class << self
        attr_reader :mutex
      end
    end
    include InstanceExecMethods

    # Evaluate the block with the given arguments within the context of
    # this object, so self is set to the method receiver.
    #
    # From Mauricio's http://eigenclass.org/hiki/bounded+space+instance_exec
    def instance_exec(*args, &block)
      method_name = InstanceExecMethods.mutex.synchronize do
        n = 0
        n += 1 while respond_to?(method_name = "__instance_exec#{n}")
        InstanceExecMethods.module_eval { define_method(method_name, &block) }
        method_name
      end

      begin
        send(method_name, *args)
      ensure
        InstanceExecMethods.module_eval { remove_method(method_name) } rescue nil
      end
    end
  end
end
