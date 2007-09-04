module Foo
  module Acts #:nodoc:
    module Indexed #:nodoc:

      # Adds instance methods.
      module InstanceMethods
        def add_to_index
          self.class.index_add(self)
        end

        def remove_from_index
          self.class.index_remove(self)
        end

        def update_index
          self.class.index_remove(self)
          self.class.index_add(self)
        end
      end

    end
  end
end