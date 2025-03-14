# frozen_string_literal: true

require 'securerandom'

class TodoComponent < Component
  Todo = Struct.new(:uuid, :title, :completed)

  attr_reactive :todos
  attr_reactive :new_todo
  attr_reactive :filter

  def initialize(todos: [])
    @all_todos = []
    @todos = todos
    @filter = :all
  end

  def add_todo
    @all_todos += [Todo.new(SecureRandom.uuid, new_todo, false)]
    apply_filter(filter)
  end

  def toggle_completed(uuid)
    todo = todos.detect { |t| t.uuid == uuid }
    todo.completed = !todo.completed
    @all_todos = todos
    apply_filter(filter)
  end

  def remove_todo(uuid)
    @all_todos = todos.reject { |todo| todo.uuid == uuid }
    apply_filter(filter)
  end

  def selected(filter_selected)
    filter == filter_selected ? 'selected' : ''
  end

  def apply_filter(filter_selected)
    self.filter = filter_selected
    case filter
    when :all
      self.todos = @all_todos
    when :completed
      self.todos = @all_todos.select(&:completed)
    when :active
      self.todos = @all_todos.reject(&:completed)
    end
  end

  def template
    <<-ERB
      <h1>Todos</h1>
      <input type="text" r-model="new_todo">
      <button r-on:click="add_todo">Add Todo</button>
      
      <menu class="flex center">
        <li class="<%= selected(:all) %>" r-on:click="apply_filter(:all)">All</li>
        <li class="<%= selected(:active) %>" r-on:click="apply_filter(:active)">Active</li>
        <li class="<%= selected(:completed) %>" r-on:click="apply_filter(:completed)">Completed</li>
      </menu>
      
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
