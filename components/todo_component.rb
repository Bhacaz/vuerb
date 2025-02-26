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

  def done(uuid)
    todo = todos.detect { |t| t.uuid == uuid }
    todo.completed = true
    self.todos = todos
  end

  def template
    <<-ERB
      <h1>Todos</h1>
      <input type="text" r-model="new_todo">
      <button r-on:click="add_todo">Add Todo</button>
      <% todos.reverse.each do |todo| %>
        <% if todo.completed %>
          <div>
            <button disabled>Done</button>
            <s><%= todo.title %></s>
          </div>
        <% else %>
          <div>
            <button r-on:click="done('<%= todo.uuid %>')">Done</button>
            <%= todo.title %>
          </div>
        <% end %>
      <% end %>
    ERB
  end
end
