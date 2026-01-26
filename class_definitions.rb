# Classes are just "souped up" modules. Therefore, everything that applies to classes also applies to modules.

puts Class.superclass

# Code inside class definitions just run, and the last value is even returned (just like blocks and methods)

result = class A
    self
end

puts result

# Ruby always keeps a reference to the current class, and all methods defined with def become instance methods of the current class

def asdf
    self
end

puts asdf
puts asdf.class.private_methods.grep(/asdf/) # any method we define at top level becomes a private instance method of Object (the current class)

# class_eval (and module_eval) changes the current class and evaluates a block in the context of the specified class

def add_greet(a_class)
    a_class.class_eval do
        def greet(name)
            puts "Hello, #{name}!"
        end
    end
end

class B
end

add_greet(B)

obj = B.new
obj.greet("Remy")

# class_eval changes the current class, so it reopens the class (just like the class keyword does)
# class_eval is more flexible than class (not scope gated, can use non-constant variables, etc.)

class C
    @var = 1
    def self.read
        @var
    end

    def read
        @var
    end

    def write(val)
        @var = val
    end
end

obj = C.new
puts obj.read # returns nil (why?)
obj.write(42)
puts obj.read
puts C.read #we have two separate @var instance variables on two separate objects (obj and C)!

# Class methods are just singleton methods of that specific class!
# Here, we're doing the same thing with class instances and object instances
class MyClass
    def MyClass.method
        puts "hi"
    end
end

MyClass.method

obj = "string object"
def obj.method
    puts "hi"
end
obj.method

# Class Macros (eg. attr_* methods)

class User

    def initialize(username)
        @username = username
    end

    def login
        puts "#{@username} is logged in!"
    end


    def self.deprecate(old_method, new_method)
        define_method(old_method) do |*args, &block|
            warn "Warning: #{old_method} is deprecated. Use #{new_method}."
            send(new_method, *args, &block)
        end
    end

    deprecate :LOGON, :login #example of a class macro
end

user = User.new("zestyLemongrass")
user.LOGON


# Subclasses can call class methods of superclasses. This is because the superclass of a class's singleton class is the singleton class of the superclass.

class X
    def self.greet #This is a method on the singleton class of X (#X)
        puts "hello!"
    end
end

class Y < X
end

Y.greet # singleton class of Y (#Y) is checked first, then singleton class of X (#X), where the greet method lives

# The superclass of an object's singleton class is the objects class

obj = X.new
obj.instance_eval do
    puts singleton_class
    puts singleton_class.superclass
end

# instance_eval also changes the current class to the singleton class of the receiver! (rare use case)

str1, str2 = "uvw", "xyz"

str1.instance_eval do
    def shout!
        upcase!
    end
end

puts str1.shout!
puts str2.respond_to?(:shout!)

# Defining attributes on a class (instead of instances)

class User
    class << self
        attr_accessor :a
    end
end

User.a = 42
puts User.a

# The superclass of the top-level singleton class is... a Class!

puts BasicObject.singleton_class.superclass

#Wrapping methods

# 1. Around Aliasing

class String
    alias_method :real_length, :length

    def length
        real_length > 7 ? "long" : "short"
    end
end

# What will these output?

puts "Stegosaurus".length
puts "Dog".real_length


# 2. Refinement wrapper

# Calling super from a refinement calls the original, unrefined method!

module StringRefinement
    refine String do
        def upcase
            "#{super}!!!!!"
        end
    end
end

using StringRefinement

puts "hello".upcase

# Prepending a module (generally considered cleaner and more explicit that refinement wrapper and around alias)

module FancyCap
    def capitalize
        "~#{super}~"
    end
end

String.class_eval do
    prepend FancyCap
end

puts "the great gatsby".capitalize