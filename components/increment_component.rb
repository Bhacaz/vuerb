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
        <h1>Count: <span r-text="count"><%= count %></span></h1>

        <h2 r-show="count.odd?">☝️</h2>
        <h2 r-show="count.even?">✌️</h2>

        <button r-on:click="increment">Increment</button>
        <button r-on:click="decrement">Decrement</button>
      </div>
    ERB
  end
end
