class Component
  def component_id
    "#{self.class}##{object_id}"
  end

  def self.attr_reactive(attr)
    define_method("#{attr}=") do |value|
      instance_variable_set("@#{attr}", value)
      ::Bus.publish(component_id, { attribute: attr, value: value })
      # self.class.rerender(self)
    end

    define_method(attr) do
      instance_variable_get("@#{attr}")
    end
  end

  def render
    ERB.new(template).result(binding)
  end

  def self.bind_events(component)
    JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-on\\:click]').to_a.each do |button|
      button.addEventListener('click') do |_event|
        args = button.getAttribute('r-on:click').to_s
        if args.start_with?('[')
          method_name, *args = JSON.parse(args)
          component.public_send(method_name, *args)
        else
          component.public_send(args)
        end
      end
    end
  end

  # Channel names will looks like "component_name#component_id/attribute_name"
  # "ComponentForm#abc123/message"
  def self.bind_models(component)
    ::Bus.subscribe(component.component_id) do |payload|
      JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-text]').to_a.each do |element|
        to_eval = element.getAttribute('r-text').to_s
        element[:innerHTML] = component.instance_eval(to_eval)
      end

      r_show(component)
    end

    JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-model]').to_a.each do |element|
      element.addEventListener('input') do |event|
        binding_name = event[:currentTarget].call(:getAttribute, 'r-model')
        component.public_send("#{binding_name}=", event[:target][:value].to_s)
      end
    end

    r_show(component)
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
