# frozen_string_literal: true

require_relative 'component'

class TodoComponent < Component
  attr_reactive :todos
  attr_reactive :done_todos
  attr_reactive :new_todo

  def initialize(todos: [])
    @todos = todos
    @done_todos = []
  end

  def add_todo
    self.todos += [new_todo]
  end

  def done(i)
    todo = todos[i]
    self.todos -= [todo]
    self.done_todos += [todo]
  end

  def template
    <<-ERB
      <h1>Todos</h1>
      <input type="text" r-model="new_todo">
      <button r-on:click="add_todo">Add Todo</button>
      <ul>
        <% todos.reverse.each_with_index do |todo, i| %>
          <li><%= todo %></li>
          <button r-on:click="done(<%= i %>)">Done</button>
        <% end %>
      </ul>
      
      <h2>Done Todos</h2>
      <ul>
        <% done_todos.each do |todo| %>
          <li><s><%= todo %></s></li>
        <% end %>
      </ul>
    ERB
  end
end
