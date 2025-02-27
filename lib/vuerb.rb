# frozen_string_literal: true

require 'js'
require 'json'
require 'erb'
require 'securerandom'

require_relative 'bus'
require_relative 'morph'
require_relative '../components/component'
require_relative '../app'
require_relative '../components/form_component'
require_relative '../components/increment_component'
require_relative '../components/random_list_component'

puts RUBY_VERSION
JS.global[:document].querySelector('h2').remove()
# # puts Http.get('https://catfact.ninja/facts?limit=2')['data']

NODE_TYPE_NODE = 1
NODE_TYPE_TEXT = 3

def mount(element, target)
  target.replaceChildren(*element)
end

def app_dom(id = 'app')
  JS.global[:document].getElementById(id)
end

def nodes_for_data_r_id(data_r_id)
  JS.global[:document].querySelectorAll("[#{data_r_id}]")
end

observer = JS.global[:MutationObserver].new do |mutations|
  mutations.to_a.each do |mutation|
    mutation[:addedNodes].to_a.each do |node|
      next unless node[:nodeType] == NODE_TYPE_NODE

      if node.getAttribute('r-source') != nil
        component_name = node.getAttribute('r-source').to_s
        component_class = Object.const_get("#{component_name}Component")
        component =
          if node.getAttribute('r-data') != nil
            data = eval(node.getAttribute('r-data').to_s)
            component_class.new(**data)
          else
            component_class.new
          end
        component.parent_node = node[:parentNode]
        component_render = component.render
        node.replaceWith(*component_render)
        component.current_nodes = component_render
        ::Bus.publish("AddedNodes/#{component.component_id}",
                      { component: component, nodes: component_render.to_a })
      end
    end
  end
end

observer.observe(app_dom, { childList: true, subtree: true })

v_app = App.new
mount(
  v_app.render,
  app_dom
)

::Bus.subscribe(%r{AddedNodes/.*}) do |payload|
  component = payload[:component]
  nodes = payload[:nodes]

  Component.bind_events(component, nodes)
  Component.bind_models(component, nodes)
end

::Bus.subscribe(%r{Reactive/.*}) do |payload|
  component = payload[:component]

  current_node_list = component.current_nodes
  new_rerender = component.render

  component.current_nodes = Morph.call(current_node_list, new_rerender, component)
end
