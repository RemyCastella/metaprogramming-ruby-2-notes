# Kernel#eval takes a string of Ruby code and executes/returns the result

array = [1,2,3]
next_element = array.last.succ

p eval("array << next_element")

# Bindings are scopes packaged as objects. We can use binding to capture local scope and carry it around!
# And later we can execute code in that scope using the binding object and eval.

class A
    def initialize
        @val = 42
    end

    def scope
        binding
    end

    def top_level_self
       eval "self", TOPLEVEL_BINDING
    end
end

obj = A.new
b = obj.scope
puts b
puts eval "@val", b
puts obj.top_level_self

# Hook methods

class String
    def self.inherited(subclass)
        puts "#{self} was inherited by #{subclass}"
    end
end

class MyString < String
end

module Validator
    def self.included(includor)
        puts "#{self} was included into #{includor}"
    end

    def self.prepended(prependor)
        puts "#{self} was prepended onto #{prependor}"
    end

    def self.extended(extendor)
        puts "#{self} was extended onto #{extendor}"
    end

    def self.method_added(method)
        puts "New method added: Validator##{method}"
    end
end

class String
    include Validator
end

class Numeric
    prepend Validator
end

obj = "test"
obj.extend Validator

Validator.module_eval do
    def validate
        "doing cool validations..."
    end
end