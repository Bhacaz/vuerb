# frozen_string_literal: true

require_relative './lib/component'
require_relative './components/editor_component'
require_relative './components/form_component'

class App < Component
  def template
    <<-ERB
      <div r-source="Editor"></div>
    ERB
  end
end

# <div r-source="Todo"></div>
# <div r-source="Increment" r-data="{ count: 0 }"></div>
# <div r-source="Form"></div>
