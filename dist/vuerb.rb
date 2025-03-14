class Bus
  @subscriptions = {}

  def self.subscribe(channel, &block)
    @subscriptions[channel] ||= []
    @subscriptions[channel] << block
  end

  def self.publish(channel, payload)
   puts "Channel: #{channel}, payload: #{payload}"

   @subscriptions.each do |pattern, handlers|
      if channel.match?(pattern)
        handlers.each do |handler|
          handler.call(payload)
        end
      end
   end
  end

  def self.clear
   @subscriptions = {}
  end
end

class Morph
  class << self
    def call(old, new, component)
      new_current_node_list = []

      old.zip(new).each do |current_node, rerender|
        patch = diff(current_node, rerender, component)
        patched_node = patch.call(current_node)
        new_current_node_list << patched_node if patched_node
      end

      if new.size > old.size
        new[old.size..].each do |node|
          new_current_node_list[-1].after(node) 
          Component.bind_events(component, [node])
          new_current_node_list << node
        end
      end
      new_current_node_list.compact
    end
    
    private

    def diff(old_dom, new_dom, component)
      if new_dom == nil
        return ->(node) { node.remove(); nil }
      end

      # Text node handling - update content instead of replacing
      if old_dom[:nodeType] == NODE_TEXT_NODE && new_dom[:nodeType] == NODE_TEXT_NODE
        if old_dom[:textContent] != new_dom[:textContent]
          return ->(node) do
            node[:textContent] = new_dom[:textContent]
            node
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
      boolean_attrs = ['checked', 'selected', 'disabled', 'readonly', 'required', 'open']
      
      # Handle new or changed attributes
      new_attrs.to_a.each do |attr|
        name = attr[:name]
        value = attr[:value]
        
        if boolean_attrs.include?(name)
          # For boolean attributes, set both property and attribute
          patches << ->(node) { 
            # Set DOM property (controls actual state)
            node[name.to_sym] = true
            # Set HTML attribute (for morphing comparison)
            node.setAttribute(name, '')
            node
          }
        else
          patches << ->(node) { node.setAttribute(name, value); node }
        end
      end

      # Handle removed attributes
      old_attrs.to_a.each do |attr|
        name = attr[:name]
        if new_attrs.getNamedItem(name) == nil
          if boolean_attrs.include?(name)
            patches << ->(node) { 
              # Remove attribute and set property to false
              node.removeAttribute(name)
              node[name.to_sym] = false
              node
            }
          else
            patches << ->(node) { node.removeAttribute(name); node }
          end
        end
      end
      
      ->(node) { patches.each { |patch| patch.call(node) }; node }
    end

    def diff_children(old_children, new_children, component)
      # Check if we should use keyed diffing
      if has_keyed_elements?(old_children) && has_keyed_elements?(new_children)
        return keyed_diff_children(old_children, new_children, component)
      end
      
      # Original position-based diffing logic...
      child_patches = []
      old_children.each_with_index do |old_child, i|
        if i < new_children.length
          child_patches << diff(old_child, new_children[i], component)
        else
          # Handle removed nodes
          child_patches << ->(node) { node.remove; nil }
        end
      end

      # Handle new children
      addition_patches = []
      if old_children.length < new_children.length
        new_children[old_children.length..].each do |new_child|
          addition_patches << ->(parent) {
            parent.appendChild(new_child)
            Component.bind_events(component, [new_child])
            parent
          }
        end
      end

      ->(node) do
        # Apply patches to existing children
        node_children = node[:childNodes].to_a
        child_patches.each_with_index do |patch, i|
          if i < node_children.length
            patch.call(node_children[i])
          end
        end
        
        # Add new children
        addition_patches.each { |patch| patch.call(node) }
        
        node
      end
    end
    
    # New keyed diffing implementation
    def keyed_diff_children(old_children, new_children, component)
      # Create key -> node maps
      old_keys = {}
      old_children.each do |child|
        if child[:nodeType] == NODE_ELEMENT_NODE
          key = child[:dataset][:key]
          old_keys[key] = child if key != nil
        end
      end
      
      new_keys = {}
      new_children.each do |child|
        if child[:nodeType] == NODE_ELEMENT_NODE
          key = child[:dataset][:key]
          new_keys[key] = child if key != nil
        end
      end
      
      # Prepare patches
      patches = []
      moves = []
      additions = []
      
      # Process new nodes in their order
      new_children.each_with_index do |new_child, new_index|
        next if new_child[:nodeType] != NODE_ELEMENT_NODE
        
        key = new_child.getAttribute('data-key')
        if key && old_keys[key]
          # Node exists in both old and new - create patch and mark for move
          old_child = old_keys[key]
          patch = diff(old_child, new_child, component)
          moves << {
            key: key,
            node: old_child,
            patch: patch,
            new_index: new_index
          }
        elsif key
          # New node with key - add it
          additions << {
            node: new_child,
            new_index: new_index
          }
        else
          # Non-keyed node, handle positionally if possible
          if new_index < old_children.length
            patch = diff(old_children[new_index], new_child, component)
            patches[new_index] = patch
          else
            additions << {
              node: new_child,
              new_index: new_index
            }
          end
        end
      end
      
      # Handle removals - nodes in old but not in new
      removals = []
      old_children.each do |old_child|
        next if old_child[:nodeType] != NODE_ELEMENT_NODE
        
        key = old_child.getAttribute('data-key')
        if key && !new_keys[key]
          removals << old_child
        end
      end
      
      # Return a function that applies all these changes
      ->(parent) do
        # 1. Remove nodes that don't exist in the new list
        removals.each do |node|
          node.remove
        end
        
        # 2. Apply patches to existing nodes by position
        parent_children = parent[:childNodes].to_a
        patches.each_with_index do |patch, i|
          if patch && i < parent_children.length
            patch.call(parent_children[i])
          end
        end
        
        # 3. Handle moves - nodes that changed position
        # First patch them
        moves.each do |move_data|
          move_data[:patch].call(move_data[:node])
        end
        
        # 4. Add new nodes and moved nodes in their correct positions
        all_insertions = moves + additions
        all_insertions.sort_by! { |item| item[:new_index] }
        
        all_insertions.each do |insertion|
          node = insertion[:node]
          # Only append if not already in the parent
          if insertion[:key]
            # For moved nodes, we need to check if it's still in the parent
            # and then move it to the right spot
            parent.appendChild(node)
          else
            # For new nodes
            parent.appendChild(node)
            Component.bind_events(component, [node])
          end
        end
        
        parent
      end
    end
    
    def has_keyed_elements?(children)
      children.any? do |child|
        child[:nodeType] == NODE_ELEMENT_NODE && child.getAttribute('data-key')
      end
    end
  end
end

class Component
  attr_accessor :parent_node, :current_nodes

  def initialize
    @current_nodes = []
  end

  def component_id
    "#{self.class}##{object_id}"
  end

  def self.attr_reactive(attr)
    define_method("#{attr}=") do |value|
      instance_variable_set("@#{attr}", value)
      ::Bus.publish("Reactive/#{component_id}", { component: self, attribute: attr, value: value })
      # self.class.rerender(self)
    end

    define_method(attr) do
      instance_variable_get("@#{attr}")
    end
  end

  def render_as_string
    ERB.new(template).result(binding)
  end

  # @return Array[JS::Object]
  def render
    body = JS.global[:DOMParser].new
             .parseFromString(render_as_string, 'text/html')[:body]

    # childNodes return string node and cannot attribute
    body[:children].to_a.each do |node|
      add_data_r_id_attribute(node)
    end

    body[:childNodes].to_a
  end

  def add_data_r_id_attribute(element)
    element.setAttribute(data_r_id, '')
    element[:children].to_a.each do |child|
      add_data_r_id_attribute(child)
    end
  end

  def data_r_id
    "data-r-#{object_id}"
  end

  def self.bind_events(component, nodes = nil)
    %w[click change].each do |event|
      bind_events_for(component, event, nodes)
    end
  end

  def self.bind_events_for(component, event_name, nodes = nil)
    nodes =
      if nodes != nil
        nodes = nodes.to_a.select { |node| node[:nodeType] == NODE_ELEMENT_NODE }
        children_nodes = nodes.flat_map { |node| node.querySelectorAll("[r-on\\:#{event_name}]").to_a }
        nodes.each do |node|
          children_nodes << node if node.hasAttribute("r-on:#{event_name}") == JS::True
        end
        children_nodes
      else
        # JS.global[:document][:body].querySelectorAll("[#{component.data_r_id}][r-on\\:#{event_name}]").to_a
      end
  
    nodes.each do |element|
      element.addEventListener(event_name) do |event|
        args = event[:target].getAttribute("r-on:#{event_name}").to_s
        component.instance_eval(args)
        # Need to return an object that respond to to_js.
        nil
      end
    end
  end

  def self.bind_models(component, nodes = nil)
    nodes =
      if nodes != nil
        nodes.to_a.select { |node| node[:nodeType] == NODE_ELEMENT_NODE }
      else
        JS.global[:document].querySelectorAll("[#{component.data_r_id}]").to_a
      end

    nodes.each do |element|
      descendants = element.querySelectorAll('[r-model]').to_a
      descendants << element if element.getAttribute('r-model') != nil
      descendants.each do |node|
        node.addEventListener('input') do |event|
          binding_name = event[:currentTarget].call(:getAttribute, 'r-model')
          component.public_send("#{binding_name}=", event[:target][:value].to_s)
        end
      end
    end
  end

  def self.r_show(component)
    JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-show]').to_a.each do |element|
      to_eval = element.getAttribute('r-show').to_s
      to_show = component.instance_eval(to_eval)
      element[:style].removeProperty('display') if to_show
      element[:style].setProperty('display', 'none') unless to_show
    end
  end

  def self.rerender(component)
    # JS.global[:document].getElementById(component.component_id)[:innerHTML] = component.render
    # bind_events(component)
   # bind_models(component)
  end
end

# frozen_string_literal: true

require 'js'
require 'json'
require 'erb'
require 'securerandom'

# Patch require_relative to load from remote
require 'js/require_remote'

module Kernel
  alias original_require_relative require_relative

  # The require_relative may be used in the embedded Gem.
  # First try to load from the built-in filesystem, and if that fails,
  # load from the URL.
  def require_relative(path)
    caller_path = caller_locations(1, 1).first.absolute_path || ''
    dir = File.dirname(caller_path)
    file = File.absolute_path(path, dir)

    original_require_relative(file)
  rescue LoadError
    JS::RequireRemote.instance.load(path)
  end
end

require_relative 'app'

puts RUBY_VERSION
# # puts Http.get('https://catfact.ninja/facts?limit=2')['data']

NODE_ELEMENT_NODE = 1
NODE_TEXT_NODE = 3

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
      next unless node[:nodeType] == NODE_ELEMENT_NODE

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

