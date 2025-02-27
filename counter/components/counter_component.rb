# frozen_string_literal: true

require_relative './component'

class CounterComponent < Component
  attr_reactive :count

  def initialize(count: 0)
    @count = count
  end

  def template
    <<~ERB
      <%= count %>
      <button r-on:click="self.count += 1">Count</button>
    ERB
  end
end
