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
