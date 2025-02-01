require_relative 'component'

class IncrementComponent < Component
  attr_accessor :count

  def initialize(count:)
    @count = count
  end

  def increment
    @count += 1
  end

  def template
    <<~HTML_ERB
      <div>
        <h1>Count: #{@count}</h1>
        <button r-on:click="increment">Increment</button>
      </div>
    HTML_ERB
  end
end
