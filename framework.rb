# frozen_string_literal: true

require 'js'
require 'json'
require 'erb'
require 'securerandom'

require_relative 'lib/http'
require_relative 'lib/bus'
require_relative 'components/component'
require_relative 'components/form_component'
require_relative 'components/increment_component'
require_relative 'components/random_list_component'

puts RUBY_VERSION # => Hello, world! (printed to the browser console)
JS.global[:document].querySelector('h2')[:innerHTML] = 'Hello world'
# puts Http.get('https://catfact.ninja/facts?limit=2')['data']

JS.global[:document].querySelectorAll('[r-source]').to_a.each do |element|
  component_name = element.getAttribute('r-source').to_s
  # require_relative "./components/#{component_name}_component"
  component_class = Object.const_get("#{component_name}Component")
  component =
    if element.getAttribute('r-data') != nil
      data = eval(element.getAttribute('r-data').to_s)
      component_class.new(**data)
    else
      component_class.new
    end
  element[:id] = component.component_id

  element[:innerHTML] = component.render
  Component.bind_events(component)
  Component.bind_models(component)
end
