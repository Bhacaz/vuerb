class Component
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
    string = render_as_string
    unless self.class.name == 'App'
      # LIMITATION: adding root div to a component because only using querySelectorAll(r-v-id) to find elements
      #   was finding/processing child element twice
      string = <<-HTML
        <div id="#{component_id}">
          #{string}
        </div>
      HTML
    end

    body = JS.global[:DOMParser].new
      .parseFromString(string, 'text/html')[:body]

    body[:children].to_a.each do |node|
      add_data_r_id_attribute(node)
    end
    body[:children]
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
    nodes =
      if nodes != nil
        nodes.to_a.select { |node| node[:nodeType] == NODE_TYPE_NODE && node.getAttribute('r-on:click') != nil }
      else
        JS.global[:document].getElementById(component.component_id).querySelectorAll("[r-on\\:click]").to_a
      end

    nodes.each do |element|
      element.addEventListener('click') do |_event|
        args = element.getAttribute('r-on:click').to_s
        component.instance_eval(args)
      end
    end
  end

  def self.bind_models(component, nodes = nil)
    nodes =
      if nodes != nil
        nodes.to_a
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
