# frozen_string_literal: true

require_relative 'components/editor_component'

class App < Component
  def template
    <<-ERB
      <div r-source="Editor"></div>
    ERB
  end
end
