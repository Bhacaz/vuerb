# frozen_string_literal: true

require_relative './components/component'

class App < Component
  def template
    <<-ERB
      <h1>App</h1>
      <div r-source="Increment" r-data="{ count: 0 }"></div>
    ERB
  end
end
