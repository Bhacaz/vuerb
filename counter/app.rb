# frozen_string_literal: true

require_relative 'components/counter_component'

class App < Component
  def template
    <<-ERB
      <div r-source="Counter"></div>
    ERB
  end
end
