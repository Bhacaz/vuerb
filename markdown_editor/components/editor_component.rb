# frozen_string_literal: true

class EditorComponent < Component
  attr_reactive :text

  def initialize
    @text = ''
  end

  def template
    <<~ERB
      <div style="display: flex; height: 90vh; padding-top: 2rem">
        <textarea style="width: 50%;" r-model="text"><%= text %></textarea>
        <div style="width: 50%; padding: 1rem">
          <%= JS.global[:marked].parse(text) %>
        </div>
    </div>
    ERB
  end
end
