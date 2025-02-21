# frozen_string_literal: true

require_relative './components/component'

class App < Component
  def template
    <<-ERB
      <h1>Ruby WEB Framework</h1>
      <div r-source="Increment" r-data="{ count: 0 }"></div>
      <div r-source="Increment" r-data="{ count: 99 }"></div>
    ERB
  end
end
