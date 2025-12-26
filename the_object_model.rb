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
# A class is an object + instance methods + a link to a superclass

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
