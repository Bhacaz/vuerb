# frozen_string_literal: true

require_relative 'components/todo_component'

class App < Component
  def template
    <<-ERB
      <div r-source="Todo"></div>
    ERB
  end
end
