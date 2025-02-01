# frozen_string_literal: true

require 'js'
require 'json'
require 'erb'

puts RUBY_VERSION # => Hello, world! (printed to the browser console)
JS.global[:document].querySelector('h2')[:innerHTML] = 'Hello world'

class Component
  def component_id
    "#{self.class}-#{object_id}"
  end

  def self.attr_reactive(attr)
    define_method("#{attr}=") do |value|
      instance_variable_set("@#{attr}", value)
      self.class.rerender(self)
    end

    define_method(attr) do
      instance_variable_get("@#{attr}")
    end
  end

  def render
    ERB.new(template).result(binding)
  end

  def self.bind_events(component)
    JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-on\\:click]').to_a.each do |button|
      button.addEventListener('click') do |_event|
        component.public_send(button.getAttribute('r-on:click').to_s)
      end
    end
  end

  def self.rerender(component)
    JS.global[:document].getElementById(component.component_id)[:innerHTML] = component.render
    bind_events(component)
  end
end

class IncrementComponent < Component
  attr_reactive :count

  def initialize(count:)
    @count = count
  end

  def increment
    self.count += 1
  end

  def decrement
    self.count -= 1
  end

  def template
    <<-ERB
      <div>
        <h1>Count: <%= count %></h1>
        <% if count.even? %>
          <h2>☝️</h2>
        <% else %>
          <h2>✌️</h2>
        <% end %>
        <button r-on:click="increment">Increment</button>
        <button r-on:click="decrement">Decrement</button>
      </div>
    ERB
  end
end

def replace_element(old_element, new_element)
  old_element.parentNode.replaceChild(new_element, old_element)
end

JS.global[:document].querySelectorAll('[r-source]').to_a.each do |element|
  component_name = element.getAttribute('r-source').to_s
  # require_relative "./components/#{component_name}_component"
  component_class = Object.const_get("#{component_name.capitalize}Component")
  data = eval(element.getAttribute('r-data').to_s)
  component = component_class.new(**data)
  element[:id] = component.component_id

  element[:innerHTML] = component.render
  Component.bind_events(component)
end
