# frozen_string_literal: true

class ItemComponent < Component
  def initialize(data)
    @data = data
    pp data
    # @uuid = uuid
    # @title = title
    # @completed = completed
  end

  def template
    <<-ERB
      <%= title %>
    ERB
  end
end
