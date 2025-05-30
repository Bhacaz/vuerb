# frozen_string_literal: true

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
      <h1 <%= count.odd? ? 'style="background-color: red"' : 'class="blue"' %>>The count is: <%= count %></h1>
      <button r-on:click="increment">Increment</button>
      <button r-on:click="decrement">Decrement</button>
      <button r-on:click="self.count = 0">Reset</button>
      <% if count.odd? %>
        <h2>Odd</h2>
      <% else %>
        <h3>Even</h3>
      <% end %>
      <% if count.even? %>
        <h2>Even again</h2>
      <% end %>
      
      <% count.times do |i| %>
        <p><%= i %></p>
      <% end %>
    ERB
  end

  # def template
  #   <<-ERB
  #     <h1>Count: <span r-text="count"><%= count %></span></h1>
  #     <h1>The time is: <%= Time.now %></h1>
  #     <h2 r-show="count.odd?">☝️</h2>
  #     <h2 r-show="count.even?">✌️</h2>
  #
  #     <button r-on:click="increment">Increment</button>
  #     <button r-on:click="decrement">Decrement</button>
  #   ERB
  # end
end
