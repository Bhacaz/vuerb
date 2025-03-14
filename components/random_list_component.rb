# frozen_string_literal: true

class RandomListComponent < Component
  attr_reactive :items

  def initialize(items: [])
    @items = items
  end

  def remove_item(item)
    self.items = items - [item]
  end

  def add_item
    self.items += [SecureRandom.hex(8)]
  end

  def template
    <<-ERB
      <button r-on:click="add_item">Add Item</button>
      <ul>
        <% items.each do |item| %>
          <li><%= item %></li> <button r-on:click=<%= ['remove_item', item].to_json %>>Remove</button>
        <% end %>
      </ul>
    ERB
  end
end