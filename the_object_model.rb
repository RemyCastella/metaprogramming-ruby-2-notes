# Adding generic string functionality to all strings
# eg. String#to_alphanumeric

class String
    def to_alphanumeric
        self.gsub(/[^\w\s]/, '')
    end
end

# Now all strings can remove non-alphanumeric characters from itself
# without us having to pass it through an external method (eg. to_alphanumeric(str))

p "$%^This is an alphanumeric string(*&*)".to_alphanumeric

# The core job of the class keyword is to move you into the context of a class, where you can define methods
# and if no class of that name exists yet, it creates that class
# Therefore, classes can always be reopened and modified!

# An object is a bunch of instance variables + a link to a class
# A class is an object + instance methods + a link to a super class

# Objects of the same class can have different instance variables

class A
    attr_accessor :data
end

obj1 = A.new
obj1.data = 42
obj2 = A.new

p obj1.instance_variables
p obj2.instance_variables

# instance methods are stored in the object's class (so all instances of the same class have the same methods)

p A.instance_methods == obj1.methods
p A.instance_methods == obj2.methods

# classes are also objects (instances of class Class)

p A.class
p Class.instance_methods(false)

# class names are just constants that point to an instance of Class

# constants are like files that live inside directories (classes and modules)
# therefore, you can have constants of the same name inside difference class/module contexts

Const = "root level constant"

module M
    Const = 42
    class C
        Const = 24
        p ::Const # you can access root level constants with ::
        p Module.nesting # see the current path
    end
end

p M::Const
p M::C::Const
p M.constants # like ls, returns all constants in M scope
p Module.constants.grep(/\AM/) # returns all constants in top-level scope

# Module names and class names can clash!

module Cat
end

# class Cat <- This will throw a TypeError!
# end

# If we also want a class Cat, we need to namespace it (Namespace::Cat)
module Namespace
    class Cat
    end
end

p Object.class
p Module.superclass
p Class.class
p Module.superclass.class.superclass.class.superclass #there are some self-referential relationships

# Ruby does two things when you call a method
# 1. Method lookup
# 2. Method execution (on self, the receiver)

# A module can only appear once in the same chain of ancestors
module M1
end

module M2
    include M1
end

p M2.ancestors

module M3
    prepend M1
    include M2 # the second inclusion of M1 within M2 is ignored
end

p M3.ancestors

# Opening Kernel to write methods callable from anywhere

module Kernel
    def greet
        system("echo hello")
    end
end

greet

# Refinements for local monkeypatching

module StringExtensions
    refine String do
        def hex
            gsub(/[A-Fa-f]/, "6")
        end
    end
end

p "ff".hex

class A
    using StringExtensions
    p "ff".hex #our hex method is only changed in the scope where our refinement was introduced
end

p "ff".hex #now we're back out of class A so #hex is back to normal

