# Metaprogramming Ruby 2 - Reading Notes

My notes from reading **Metaprogramming Ruby 2** by Paolo Perrotta.

---

### [the_m_word.rb](the_m_word.rb)

Metaprogramming = writing code that manipulates language constructs (variables, classes, methods) at runtime. 

Languages like C separate compile time and runtime, so constructs aren't accessible at runtime. Ruby has no compile time, keeping all constructs available.

---

### [the_object_model.rb](the_object_model.rb)

#### Open Classes

The `class` keyword moves you into the class context to define methods. If the class doesn't exist, it creates one. Classes can always be reopened and modified:

```ruby
class String
    def to_alphanumeric
        self.gsub(/[^\w\s]/, '')
    end
end

"$%^Hello(*&*)".to_alphanumeric  # => "Hello"
```

#### Objects and Classes

- An object = instance variables + link to a class
- A class = object + instance methods + link to superclass
- Objects of the same class can have different instance variables
- Instance methods live on the class, so all instances share the same methods

```ruby
class A
    attr_accessor :data
end

obj1 = A.new
obj1.data = 42
obj2 = A.new

obj1.instance_variables  # => [:@data]
obj2.instance_variables  # => []

A.instance_methods == obj1.methods  # => true
```

#### Classes are Objects

Classes are instances of `Class`. Class names are just constants pointing to `Class` instances.

```ruby
A.class                    # => Class
Class.instance_methods(false)  # => [:allocate, :new, :superclass]
```

#### Constants and Namespacing

Constants live inside classes/modules like files in directories. You can have same-named constants in different contexts:

```ruby
Const = "root level"

module M
    Const = 42
    class C
        Const = 24
        ::Const         # Access root-level constant
        Module.nesting  # See current path
    end
end

M::Const             # => 42
M::C::Const          # => 24
M.constants          # Like ls, returns constants in M
Module.constants     # All top-level constants
```

Module and class names can clash—`module Cat` and `class Cat` can't coexist at the same level. Use namespacing to avoid conflicts.

#### Class/Module Relationships

```ruby
Object.class                              # => Class
Module.superclass                         # => Object
Class.class                               # => Class
Module.superclass.class.superclass.class  # Self-referential relationships
```

#### Method Lookup

When calling a method, Ruby: (1) looks up the method, (2) executes it on `self` (the receiver).

A module appears only once in the ancestor chain:

```ruby
module M1; end

module M2
    include M1
end

M2.ancestors  # => [M2, M1]

module M3
    prepend M1
    include M2  # Second inclusion of M1 is ignored
end

M3.ancestors  # => [M1, M3, M2]
```

#### Kernel Methods

Methods defined in `Kernel` are callable from anywhere:

```ruby
module Kernel
    def greet
        system("echo hello")
    end
end

greet  # Works anywhere
```

#### Refinements

Scoped monkeypatching with `refine` and `using`. The refined behavior only applies within the scope where `using` is called:

```ruby
module StringExtensions
    refine String do
        def hex
            gsub(/[A-Fa-f]/, "6")
        end
    end
end

"ff".hex  # => 255 (original)

class A
    using StringExtensions
    "ff".hex  # => "66" (refined behavior)
end

"ff".hex  # => 255 (back to original)
```

---

### [methods.rb](methods.rb)

#### Dynamic Dispatch

Call methods dynamically using `send` or `public_send`:

```ruby
class User
    attr_accessor :first_name, :last_name

    def update(**args)
        args.each do |key, value|
            public_send("#{key}=", value) if respond_to?("#{key}=")
        end
    end
end
```

#### Dynamic Method Definition

Use `define_method` to create methods at runtime, reducing repetition:

```ruby
class Computer
    def self.define_component(name)
        define_method(name) do
            info = @data_source.public_send("get_#{name}_info", @id)
            "#{name.capitalize}: #{info}"
        end
    end

    define_component :cpu
    define_component :mouse
end
```

#### Ghost Methods with method_missing

Respond to method calls without defining methods explicitly:

```ruby
class MethodMissingComputer
    def method_missing(method_name, *args)
        super unless @data_source.respond_to?("get_#{method_name}_info")
        @data_source.send("get_#{method_name}_info", @id)
    end

    def respond_to_missing?(method_name, include_private = false)
        @data_source.respond_to?("get_#{method_name}_info") || super
    end
end
```

Always call `super` for unknown methods and override `respond_to_missing?`. Use `undef_method` or inherit from `BasicObject` to avoid conflicts with existing methods like `display`.

There's also `const_missing` for handling missing constants.

Dynamic methods are generally safer than ghost methods.

---

### [blocks.rb](blocks.rb)

#### Blocks Capture Local Bindings

Blocks are closures—they capture variables from the scope where they're defined:

```ruby
name = "Sally"
greet { |greeting| puts "#{greeting}, #{name}" }  # Uses "Sally", not any inner variable
```

#### Scope Gates

Three constructs open new scopes (previous local variables become invisible):
- `class` definitions
- `module` definitions
- `def` methods

#### Flattening the Scope

Use `Class.new` and `define_method` (method calls, not keywords) to pass variables through:

```ruby
local = 42

MyClass = Class.new do
    puts local  # Accessible!

    define_method(:my_method) do
        puts local  # Still accessible!
    end
end
```

#### instance_eval and instance_exec

`instance_eval` changes `self` to the receiver while keeping access to local variables:

```ruby
obj = SomeClass.new
v = "local"
obj.instance_eval do
    puts @instance_var  # Access obj's instance variables
    @instance_var = v   # Can use outer local variables
end
```

Use `instance_exec` to pass arguments into the block.

#### Procs, Lambdas, and Methods

All are callable objects. Key differences between Procs and Lambdas:

| | Proc | Lambda |
|---|---|---|
| `return` | Returns from enclosing method | Returns from lambda only |
| Arity | Tolerant (ignores extra args) | Strict (raises ArgumentError) |

```ruby
inc = Proc.new { |n| n + 1 }
dec = ->(n) { n - 1 }

inc.call(41)  # => 42
dec.call(43)  # => 42
```

The `&` operator converts between blocks and procs. Methods can be converted to procs with `Method#to_proc`.

---

### [class_definitions.rb](class_definitions.rb)

#### Classes Are Modules

`Class.superclass` is `Module`. Everything that applies to modules applies to classes.

#### Code in Class Definitions Executes

Class bodies run like any other code and return the last expression:

```ruby
result = class A
    self
end
result  # => A
```

#### Current Class

Ruby tracks a "current class"—methods defined with `def` become instance methods of it. Top-level methods become private instance methods of `Object`.

#### class_eval

Opens a class like the `class` keyword but without scope gating:

```ruby
def add_greet(klass)
    klass.class_eval do
        def greet(name)
            puts "Hello, #{name}!"
        end
    end
end
```

#### Singleton Methods and Classes

Class methods are just singleton methods on the class object:

```ruby
class MyClass
    def self.my_method; end      # Singleton method
end

obj = "string"
def obj.shout; upcase; end       # Singleton method on obj
```

The singleton class hierarchy: an object's singleton class has the object's class as its superclass. A class's singleton class has the superclass's singleton class as its superclass.

#### Class Macros

Methods called at class definition time (like `attr_accessor`):

```ruby
class User
    def self.deprecate(old_method, new_method)
        define_method(old_method) do |*args, &block|
            warn "#{old_method} is deprecated"
            send(new_method, *args, &block)
        end
    end

    deprecate :old_login, :login
end
```

#### Method Wrapping

Three approaches:

1. **Around Alias**: `alias_method :original, :method` then redefine
2. **Refinement Wrapper**: Call `super` in a refinement to invoke original
3. **Prepend** (cleanest): Prepend a module that calls `super`

```ruby
module FancyCap
    def capitalize
        "~#{super}~"
    end
end

String.prepend FancyCap
"hello".capitalize  # => "~Hello~"
```

---

### [code_that_writes_code.rb](code_that_writes_code.rb)

#### eval

Executes a string as Ruby code:

```ruby
array = [1, 2, 3]
eval("array << 4")  # => [1, 2, 3, 4]
```

#### Bindings

A binding captures a scope as an object, letting you execute code in that context later:

```ruby
class A
    def initialize
        @val = 42
    end

    def scope
        binding
    end
end

b = A.new.scope
eval("@val", b)  # => 42
```

`TOPLEVEL_BINDING` provides access to the top-level scope.

#### Hook Methods

Methods called automatically when certain events occur:

```ruby
class Parent
    def self.inherited(subclass)
        puts "#{subclass} inherited from #{self}"
    end
end

module M
    def self.included(klass)
        puts "#{self} included in #{klass}"
    end

    def self.prepended(klass)
        puts "#{self} prepended to #{klass}"
    end

    def self.extended(obj)
        puts "#{self} extended #{obj}"
    end

    def self.method_added(method)
        puts "Method #{method} added"
    end
end
```
