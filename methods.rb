# In statically typed languages, the compiler checks if the receiving object has a matching method
# In dynamically typed languages, when a receiving object doesn't have a method, the program fails only when that line of code is executed

# Dynamic methods

# Dynamic dispatch: calling methods dynamically

class User
    attr_accessor :first_name, :last_name, :country, :city, :points

    def initialize(**args)
        update(**args)
    end

    def update(**args)
        permitted_attributes = [:first_name, :last_name, :country, :city, :points]

        args.each do |key, value|
            setter_method = "#{key}="

            if permitted_attributes.include?(key) && respond_to?(setter_method)
                public_send(setter_method, value)
                puts "Updated #{key} to: #{value}"
            else
                puts "'#{key}' is not a permitted attribute"
            end
        end
    end
end

user = User.new(first_name: "Marc", last_name: "Jacobs", country: "USA", city: "NYC", points: 12)
user.update(first_name: "John")
user.update(street: "42nd Street")

# Defining methods dynamically

class MockDataSource
  def get_cpu_info(id)
    "Intel i9"
  end

  def get_cpu_price(id)
    120
  end

  def get_mouse_info(id)
    "Logitech Wireless"
  end

  def get_mouse_price(id)
    60
  end

  def get_keyboard_info(id)
    "Mechanical Keychron"
  end

  def get_keyboard_price(id)
    80
  end

  def get_display_info(id)
    "Sony Xperia 42"
  end

  def get_display_price(id)
    320
  end

  #...
end

ds = MockDataSource.new

=begin

Solution without dynamic method calls or definitions

class Computer
    def initialize(id, data_source)
        @id = id
        @data_source = data_source
    end

    def cpu
        info = @data_source.get_cpu_info
        price = @data_source.get_cpu_price
        result = "CPU: #{info} ($#{price})"
        return "* #{result}" if price >= 100
        result
    end

    def mouse
        info = @data_source.get_mouse_info
        price = @data_source.get_mouse_price
        result = "Mouse: #{info} ($#{price})"
        return "* #{result}" if price >= 100
        result
    end

    ...
end

=end

=begin

We can refactor the redundant code within each instance method via dynamic method calls

class Computer
    def initialize(id, data_source)
        @id = id
        @data_source = data_source
    end

    def cpu
        component(:cpu)
    end

    def mouse
        component(:mouse)
    end

    ...

    def component(name)
        info = @data_source.public_send("get_#{name}_info", @id)
        price = @data_source.public_send("get_#{name}_price", @id)
        result = "#{name.capitalize}: #{info} ($#{price})"
        return "* #{result}" if price >= 100
        result
    end
end

=end

# Finally we can also use dynamic method definition to get rid of the repeated definitions

class DynamicMethodComputer
    def initialize(id, data_source)
        @id = id,
        @data_source = data_source
        data_source.methods.grep(/^get_(?<component>.*)_info$/) do
            match_data = Regexp.last_match
            DynamicMethodComputer.define_component(match_data[:component])
            #this allows use to remove the define_component calls
            #is is also flexible in that new attributes to our data source will be accounted for automatically
        end
    end

    def self.define_component(name)
        define_method(name) do
            info = @data_source.public_send("get_#{name}_info", @id)
            price = @data_source.public_send("get_#{name}_price", @id)
            result = "#{name.capitalize}: #{info} ($#{price})"
            return "* #{result}" if price >= 100
            result
        end
    end

    # define_component :cpu
    # define_component :mouse
    # define_component :keyboard
end

c = DynamicMethodComputer.new(42, ds)
puts c.cpu
puts c.mouse
puts c.keyboard

# Method missing

# When we need to define many similar methods, we can use method missing to respond to calls (without defining the methods)

class User
    def method_missing(method_name, *args, &block)
        puts "Method: #{method_name}"
        puts "Arguments: #{args}"
        puts "Block: #{block}" if block_given?
        puts "Error: undefined method (#{method_name})"
    end
end

u = User.new
u.award_points(5){ puts "Here are some points!" }

class MethodMissingComputer
    def initialize(computer_id, data_source)
        @id = computer_id
        @data_source = data_source
    end

    def method_missing(method_name, *args, &block)
        super if !@data_source.respond_to?("get_#{method_name}_info") # if its the wrong method, call BasicObject#method_missing
        info = @data_source.send("get_#{method_name}_info", @id)
        price = @data_source.send("get_#{method_name}_price", @id)
        result = "#{method_name.capitalize}: #{info} ($#{price})"
        return "* #{result}" if price >= 100
        result
    end

    def respond_to_missing?(method_name, include_private=false) # necessary with method_missing, so that respond_to? works correctly with ghost methods
        @data_source.respond_to?("get_#{method_name}_info") || super
    end
end

c2 = MethodMissingComputer.new(42, ds)

p c2.mouse
p c2.keyboard
p c2.respond_to?(:cpu) #without overwriting respond_to_missing, this would have returned false, even if the object does respond to #cpu

# But what about something like :display, which is a method in Object?
# method_missing won't be called

p c2.display

# There are a few ways to solve this. One way is to make MethodMissingComputer inherit from BasicObject (a blank slate)
# Anthor way is undef_method or remove_method

class MethodMissingComputer
    undef_method :display
end

p c2.display

# There is also const_missing

class User
    def self.const_missing(const_name)
        puts "#{const_name} does not exist in #{self}"
    end
end

User::Username

# Ghost methods can be dangerous.
# Always call super and redefine respond_to_missing
# Dynamic Methods are safer in general (they are regular methods defined during runtime)