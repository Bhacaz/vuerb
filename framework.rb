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

puts RUBY_VERSION # => Hello, world! (printed to the browser console)
JS.global[:document].querySelector('h2').remove()
# puts Http.get('https://catfact.ninja/facts?limit=2')['data']

# JS.global[:document].querySelectorAll('[r-source]').to_a.each do |element|
#   component_name = element.getAttribute('r-source').to_s
#   # require_relative "./components/#{component_name}_component"
#   component_class = Object.const_get("#{component_name}Component")
#   component =
#     if element.getAttribute('r-data') != nil
#       data = eval(element.getAttribute('r-data').to_s)
#       component_class.new(**data)
#     else
#       component_class.new
#     end
#   element[:id] = component.component_id
#
#   element[:innerHTML] = component.render
#   Component.bind_events(component)
#   Component.bind_models(component)
# end

# parser = JS.eval('return new DOMParser()')
# puts parser
#        .parseFromString(IncrementComponent.new(count: 0).render, 'text/html')[:body]
#        .querySelectorAll('[r-on\\:click]').to_a

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
        component_render = component.render
        puts "#{__FILE__}:#{__LINE__}\n"
        p component_render[:length]
        node.replaceWith(*component_render)
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

# Component.bind_events(v_app)

::Bus.subscribe(%r{AddedNodes/.*}) do |payload|
  component = payload[:component]
  nodes = payload[:nodes]

  Component.bind_events(component, nodes)
end

::Bus.subscribe(%r{Reactive/.*}) do |payload|
  component = payload[:component]

  from_real_dom = nodes_for_data_r_id(component.data_r_id)
  from_rerender = component.render
  puts from_real_dom.to_a.map { |node| node[:outerHTML] }.join("\n")
  puts from_rerender.to_a.map { |node| node[:outerHTML] }.join("\n")
  from_real_dom.to_a.zip(from_rerender.to_a).each do |real_dom, rerender|
    patch = diff(real_dom, rerender)
    patch.call(real_dom)
  end
end

def diff(old_dom, new_dom)
  puts "#{__FILE__}:#{__LINE__}\n\n"
  # p old_dom[:outerHTML]
  # p new_dom[:outerHTML]
  if new_dom == nil
    return ->(node) { node.remove(); nil }
  end

  # String change
  if old_dom[:nodeType] == NODE_TYPE_TEXT && new_dom[:nodeType] == NODE_TYPE_TEXT
    puts "#{__FILE__}:#{__LINE__}\n"
    puts old_dom[:textContent]
    puts new_dom[:textContent]
    if old_dom[:textContent] != new_dom[:textContent]
      puts "#{__FILE__}:#{__LINE__}\n"
      return ->(node) { puts node[:outerHTML]; node[:textContent] = new_dom[:textContent]; new_dom }
    else
      return ->(node) { node }
    end
  end

  # Tag change
  if old_dom[:tagName] != new_dom[:tagName]
    return ->(node) { node.replaceWith(new_dom); new_dom }
  end

  # diff_attributes(old_dom[:attributes], new_dom[:attributes])
  diff_children(old_dom[:childNodes].to_a, new_dom[:childNodes].to_a)
end

def diff_attributes(old_attrs, new_attrs)
  new_attrs.each do |k, v|

  end
end

def diff_children(old_children, new_children)
  child_patches =
    old_children.zip(new_children).map do |old_child, new_child|
      diff(old_child, new_child)
    end
  ->(node) { child_patches.each { |patch| patch.call(node) }; node }

  # add_patches = new_children.drop(old_children.length).map do |new_child|
  #   ->(node) { node.appendChild(new_child) }
  # end
  #
  # ->(node) do
  #   node.childNodes.each_with_index do |child, i|
  #     child_patches[i].call(child)
  #   end
  #
  #   add_patches.each do |patch|
  #     patch.call(node)
  #   end
  # end
end

# v_new_dom = IncrementComponent.new(count: 0).render

# patch is a list of functions to call to update the DOM
# patch = diff(app_dom('app')[:childNodes], v_new_dom)



