# frozen_string_literal: true

require_relative 'component'

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
