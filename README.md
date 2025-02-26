# ruby-web-framework-wasm

```shell
ruby -run -e httpd . -p 8000
```

## Notes

* https://dev.to/ycmjason/building-a-simple-virtual-dom-from-scratch-3d05
* https://github.com/ycmjason-talks/2018-11-21-manc-web-meetup-4/blob/master/src/vdom/diff.js
* https://todomvc.com/examples/vue/dist/#/
* https://github.com/tastejs/todomvc/blob/gh-pages/examples/vue/src/components/TodoItem.vue

Try to build a web framework in Ruby using ruby.wasm

* Use ERB for templating
* Use `r-*` attributes for binding events and data
* `r-on:click` must be a symbol of a proc evaluated in the context of the component instance
* Need a change listener when a "props" (instance variables) change

## It could look like this

```ruby
# components/increment_component.rb

class IncrementComponent < RComponent
  attr_accessor :count

  def initialize(count:)
    @count = count
  end
  
  def increment
    @count += 1
  end

  def template
    <<~HTML_ERB
      <div>
        <h1>Count: #{@count}</h1>
        <button r-on:click="increment">Increment</button>
        <p>Is odd? <%= @count.odd? %></p> 
      </div>
    HTML_ERB
  end
end
```

```html
<!-- index.html -->

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Increment</title>
</head>
<body>
  <script src="ruby-web-framework-wasm/main.js"></script>

  <div r-source="increment" r-data="{ count: 0 }"></div>
</body>
</html>
```
