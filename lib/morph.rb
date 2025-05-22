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

    def keyed_diff_children(old_children, new_children, component)
      # Create key -> node maps
      old_keys = {}
      old_children.each do |child|
        if child[:nodeType] == NODE_ELEMENT_NODE
          key = parse_key(child[:dataset][:key])
          old_keys[key] = child if key
        end
      end

      new_keys = {}
      new_children.each do |child|
        if child[:nodeType] == NODE_ELEMENT_NODE
          key = parse_key(child[:dataset][:key])
          new_keys[key] = child if key
        end
      end
      
      # Prepare patches
      patches = []
      moves = []
      additions = []

      # Process new nodes in their order
      new_children.each_with_index do |new_child, new_index|
        next if new_child[:nodeType] != NODE_ELEMENT_NODE
        
        key = parse_key(new_child.getAttribute('data-key'))
        if key && old_keys.key?(key)
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
        
        key = parse_key(old_child.getAttribute('data-key'))
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
        child[:nodeType].to_i == NODE_ELEMENT_NODE && parse_key(child.getAttribute('data-key'))
      end
    end

    def parse_key(key)
      key = key.to_s
      return if key.empty?

      key
    end
  end
end
