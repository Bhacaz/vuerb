# frozen_string_literal: true

require_relative './components/component'
require_relative './components/todo_component'

class App < Component
  def template
    <<-ERB
      <h1>Ruby WEB Framework</h1>
      <div r-source="Todo"></div>
    ERB
  end
end

# <div r-source="Todo"></div>
# <div r-source="Increment" r-data="{ count: 0 }"></div>
# <div r-source="Form"></div>
