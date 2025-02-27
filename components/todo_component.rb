# frozen_string_literal: true

require_relative 'component'
require 'securerandom'

class TodoComponent < Component
  Todo = Struct.new(:uuid, :title, :completed)

  attr_reactive :todos
  attr_reactive :new_todo

  def initialize(todos: [])
    @todos = todos
  end

  def add_todo
    self.todos += [Todo.new(SecureRandom.uuid, new_todo, false)]
  end

  def toggle_completed(uuid)
    todo = todos.detect { |t| t.uuid == uuid }
    todo.completed = !todo.completed
    self.todos = todos
  end
  
  def remove_todo(uuid)
    self.todos = todos.reject { |todo| todo.uuid == uuid }
  end

  def template
    <<-ERB
      <h1>Todos</h1>
      <input type="text" r-model="new_todo">
      <button r-on:click="add_todo">Add Todo</button>
      <% todos.reverse.each do |todo| %>
        <div data-key="<%= todo.uuid %>">
          <input 
            type="checkbox" 
            r-on:change="toggle_completed('<%= todo.uuid %>')" 
            <%= todo.completed ? "checked" : "" %>
          >
          <span <%= todo.completed ? "style='text-decoration: line-through'" : "" %>>
            <%= todo.title %>
          </span>
          <button r-on:click="remove_todo('<%= todo.uuid %>')" style="margin-left: 8px;">Delete</button>
        </div>
      <% end %>
    ERB
  end
end
