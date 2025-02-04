class Component
  def component_id
    "#{self.class}-#{object_id}"
  end

  def self.attr_reactive(attr)
    define_method("#{attr}=") do |value|
      instance_variable_set("@#{attr}", value)
      self.class.rerender(self)
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

  def self.bind_models(component)
    JS.global[:document].getElementById(component.component_id).querySelectorAll('[r-model]').to_a.each do |element|
      element.addEventListener('input') do |event|
        component.public_send("#{element.getAttribute('r-model')}=", event[:target][:value])
      end
    end
  end

  def self.rerender(component)
    JS.global[:document].getElementById(component.component_id)[:innerHTML] = component.render
    bind_events(component)
    bind_models(component)
  end
end
