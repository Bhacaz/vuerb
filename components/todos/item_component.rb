# frozen_string_literal: true

class ItemComponent < Component

  # @param [Todo] item
  def initialize(todo)
    @todo = todo
  end

  def template
    <<-ERB
      <div data-key="<%= @todo.uuid %>">
        <input
          type="checkbox"
          r-on:change="toggle_completed('<%= @todo.uuid %>')"
          <%= @todo.completed ? "checked" : "" %>
        >
        <span <%= @todo.completed ? "style='text-decoration: line-through'" : "" %>>
          <%= @todo.title %>
        </span>
        <button r-on:click="remove_todo('<%= @todo.uuid %>')" style="margin-left: 8px;">Delete</button>
      </div>
    ERB
  end
end
