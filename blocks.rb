# Blocks capture local bindings

def greet
    name = "Sam"
    yield("Hello")
end

name = "Sally"

# Which name is output below?

greet{|greeting| puts "#{greeting}, #{name}"}

def yielder
    yield
end

count = 0

yielder do
    count += 1
    block_variable = 42
end

puts count
# puts block_variable <- this is an error!

# You can define top-level instance variables (on main),
# which are accessible when self is main

@var = 42

def return_var
    @var
end

puts return_var

class A
    # self is not main so the top level @var is not visible
    puts "Self: #{self}, @var: #{@var}"
end

=begin
The 3 scope gates (where the previous scope is left behind and a new one is opened):
- Class definitions
- Module definitions
- Methods
=end

local = 42

def my_method
    # local <- throws an error because my_method does not have access to the 'local' local variable
end

my_method

# self controls instance variables, scope gates control local variables

# How to pass local variables through scope gates (flattening the scope)

B = Class.new do # This is a method call, so not a scope gate. Therefore, we can pass local variables through!

    puts local

    define_method(:my_method) do #This is also a method call, so we can pass local variables through it!
        puts local
    end
end

B.new.my_method

# Sharing variables selectively via shared scope

def define_methods
    shared = "hello"

    Kernel.send(:define_method, :show) do
        shared
    end

    Kernel.send(:define_method, :surprise) do
        shared.concat("!")
    end
end

define_methods
puts show
surprise
surprise
puts show
# puts shared -> error because we can't see the shared variable outside the define_methods scope!

#instance_eval switches self to the receiver, but has access to local variables (as blocks are not scope gates)

class C
    def initialize
        @v = "instance variable of class C"
    end
end
v = "local variable in top level"
obj = C.new
obj.instance_eval do 
    puts @v
    @v = v #we have access to top level local variables
    puts @v
end

class D
    def initialize
        @x = 1
    end
end

class E
    def initialize
        @y = 2

        puts D.new.instance_eval{ "@x: #{@x}, @y: #{@y}" }
    end

    def exec
        puts D.new.instance_exec(@y){ |y| "@x: #{@x}, @y: #{y}" }
    end
end

e = E.new #@y is nil because self is class D
e.exec #with instance_exec we can pass variables!

# Storing code and executing it later (procs, lambdas, methods)

# Procs and lambdas are block that has been turned into an object

inc = Proc.new {|n| n + 1}
puts inc.call(41)

dec = ->(n) { n - 1 }
puts dec.call(43)

# The & operator also converts a block to a proc

def greet(&name)
    time = Time.now.strftime("%H").to_i
    case time
    when 4...12
        puts "Good morning, #{name.call}"
    when 12...18
        puts "Good afternoon, #{name.call}"
    when 18...24
        puts "Good evening, #{name.call}"
    else
        puts "#{name.call}, go to sleep!"
    end
end

greet{"Remy"}

# The & operator also converts proc -> block

def apply_math(a, b)
    yield(a, b)
end

adder = ->(a,b){ a + b }
multiplier = ->(a,b){ a * b }
power = ->(a,b){ a ** b }

puts apply_math(3,5, &adder)
puts apply_math(3,5, &multiplier)
puts apply_math(3,5, &power)

# Procs vs Lambdas
# return keyword in lambdas returns only from the lambda
# return keyword in procs return from the scope where the proc was defined

def example
    p = Proc.new {return 10}
    result = p.call # unreachable code
    return result * 2 # unreachable code
end

p example

# we could have avoided this by omitting the return keyword!

# Lambdas are less tolerant to arity (argument number) issues than Procs

proc = Proc.new{|a, b| [a, b] }
lambda = ->(a,b) { [a, b] }
p proc.call(1, 2, 3)
# p lambda.call(1, 2, 3) this throws an ArgumentError!

# Methods are also callable objects (like lambdas and procs)
# We can get the Method object with Kernel#method, and later execute with Method#call
# We can even convert a method to a proc (Method#to_proc) and block into a method with define_method!
# That's what makes something like this possible:

p [1,2,3].inject(&:*)


