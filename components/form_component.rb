# frozen_string_literal: true

require_relative 'component'

class FormComponent < Component
  attr_reactive :message

  def initialize
    @message = ''
  end

  def template
    # r-text allow to know that the
    <<-ERB
      <input type="text" r-model="message" value="<%= message %>">
      <p>The message is: <span r-bind="message"></span></p>
    ERB
  end
end
