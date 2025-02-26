# frozen_string_literal: true

require 'js'
require 'json'
require 'erb'
require 'securerandom'

require_relative 'lib/http'
require_relative 'lib/bus'
require_relative 'components/component'
require_relative 'app'
require_relative 'components/form_component'
require_relative 'components/increment_component'
require_relative 'components/random_list_component'

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
                      { component: component })
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
  new_current_node_list = []

  # puts from_real_dom.size
  # puts from_rerender.size
  # puts current_node_list.each_with_index.map { |node, i| "#{i}: #{node[:textContent]}" }.join("\n")
  # puts new_rerender.map { |node| node[:textContent] }.join("\n")
  # puts new_rerender[:outerHTML]

  current_node_list.zip(new_rerender).each do |current_node, rerender|
    patch = diff(current_node, rerender, component)
    new_current_node_list << patch.call(current_node)
  end

  if new_rerender.size > current_node_list.size
    new_rerender[current_node_list.size..].each do |node|
      component.parent_node.appendChild(node)
      Component.bind_events(component, [node])
      new_current_node_list << node
    end
  end

  component.current_nodes = new_current_node_list.compact

end

def diff(old_dom, new_dom, component)
  if new_dom == nil
    return ->(node) { node.remove(); nil }
  end

  # String change
  if old_dom[:nodeType] == NODE_TYPE_TEXT && new_dom[:nodeType] == NODE_TYPE_TEXT
    if old_dom[:textContent] != new_dom[:textContent]
      return ->(node) do
        node[:textContent] = new_dom[:textContent]
        new_dom
      end
    else
      return ->(node) { node }
    end
  end

  # Tag change
  if old_dom[:tagName] != new_dom[:tagName]
    return ->(node) do
      node.replaceWith(new_dom)
      Component.bind_events(component, [new_dom])
      new_dom
    end
  end

  attr_patches = diff_attributes(old_dom[:attributes], new_dom[:attributes])
  children_patched = diff_children(old_dom[:childNodes].to_a, new_dom[:childNodes].to_a, component)
  ->(node) do
    attr_patches.call(node)
    children_patched.call(node)
    node
  end
end

def diff_attributes(old_attrs, new_attrs)
  patches = []
  new_attrs.to_a.each do |attr|
    patches << ->(node) { node.setAttribute(attr[:name], attr[:value]); node }
  end

  old_attrs.to_a.each do |attr|
    if new_attrs.getNamedItem(attr[:name]) == nil
      patches << ->(node) { node.removeAttribute(attr[:name]); node }
    end
  end
  ->(node) { patches.each { |patch| patch.call(node) }; node }
end

def diff_children(old_children, new_children, component)
  child_patches =
    old_children.each_with_index.map do |old_child, i|
      diff(old_child, new_children[i], component)
    end

  addition_patches = new_children.drop(old_children.size).map do |new_child|
    ->(node) {
      node.appendChild(new_child)
      Component.bind_events(component, [new_child])
      new_child
    }
  end

  ->(node) do
    child_patches.zip(node[:childNodes].to_a).each do |patch, child|
      patch.call(child)
    end

    addition_patches.each do |patch|
      patch.call(node)
    end

    node
  end
end
