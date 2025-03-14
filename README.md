# vuerb

A web client framework to build reactive web app in Ruby with WebAssembly.

## Concept

The framwork use only standard Ruby libs which include `ERB` to render HTML.
The render is then morphed to the actual DOM.

It need less directive like `v-if` or `v-for` because it can be done using Ruby and `ERB`.

Some directive is still needed to register listener.

## Preview

The classic simple counter example looks like this.

```ruby
class CounterComponent < Component
  attr_reactive :count

  def initialize(count: 0)
    @count = count
  end

  def template
    <<~ERB
      <%= count %>
      <button r-on:click="self.count += 1">Count</button>
    ERB
  end
end
```

See it live https://bhacaz.github.io/vuerb/counter

More [examples](https://github.com/Bhacaz/vuerb/blob/gh-pages/README.md).

## Usage

### Create an application

You need 2 files to get started:

* `./index.html`
* `./app.rb`

```html
<!DOCTYPE html>
<html lang="en">
  <head>
      <title>VueRB</title>
      <script src="https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.1/dist/browser.script.iife.js"></script>
      <script type="text/ruby" data-eval="async" src="https://raw.githubusercontent.com/Bhacaz/vuerb/refs/tags/v0.1.0/dist/vuerb.rb"></script>
  </head>
  <body>
      <div id="app">Loading...</div>
  </body>
</html>
```

The `App` class is the main component of the application.

```ruby
class App < Component
  def template
    <<-ERB
      <h1>Hello VueRB</h1>
    ERB
  end
end
```

### Running the application

Simply launch a web server in the root of the project like [http-server](https://www.npmjs.com/package/http-server) or
with Ruby:

```shell
ruby -run -e httpd . -p 8000
```

Then open the browser at http://localhost:8000.

## Component

A component is a class that inherit from `Component`. They must be located in the `./components` folder and the class
name must end with `Component`.

```ruby
# ./components/MyComponent.rb

class MyComponent < Component
  def template
    <<-ERB
      <h1>My new component</h1>
    ERB
  end
end
```

### Require and mount a component

To use a component in another component, you need to:

1. Import the component at the top of the file.
2. Use the `r-source` directive to render the component, without the `Component` suffix.

```ruby
require_relative 'components/my_component'

class App < Component
  def template
    <<-ERB
      <div r-source="My"></div>
    ERB
  end
end
```

### Reactive attributes

To make an attribute reactive, use the `attr_reactive` method. When the 
value of the attribute is reassigned using the **setter**, the component will be re-rendered.

```ruby
class CounterComponent < Component
  attr_reactive :count

  def initialize(count: 0)
    @count = count
  end

  def template
    <<~ERB
      <%= count %>
      <button r-on:click="self.count += 1">Count</button>
    ERB
  end
end
```

> [!IMPORTANT]
> Using `Array#concat` or `Array#push` will not trigger a re-render.
> It must be reassigned `self.array += ['new_item']`.

## Directives

### r-on:

- click
- change

The value to this attribute use inline Ruby code that will be evalutated in the context of the
instance of the component.

```html
<button r-on:click="self.count += 1">Count</button>
```

### r-model

Set the name of an `attr_reactive` so on input change the new value is assign to the 
`attr_reactive`.

```ruby
class MyComponent < Component
  attr_reactive :message

  def template
    <<-ERB
      <input r-model="message" value="<%= message %>">
      <p>The message is: <%= message %></p>
    ERB
  end
end
```

### r-source

Used to render a component. WIP will change to use custom HTML tag.

```html
<div r-source="Count"></div>
```

Will render the `CountComponent`

### r-data

To pass initial data to the initializer of a component.

```ruby
class CountComponent < Component
  attr_reactive :count

  def initialize(count:)
    @count = count
  end
end
```

```html
<div r-source="Count" r-data="{ count: 42 }"></div>
```

### data-key (each)

To help during morphing.

```html
<% todos.each do |todo|
 <div data-key=<%= todo.id %>>
  <h1><%= todo.title %></h1>
 </div>
<% end %>
```

## Notes

* https://dev.to/ycmjason/building-a-simple-virtual-dom-from-scratch-3d05
* https://github.com/ycmjason-talks/2018-11-21-manc-web-meetup-4/blob/master/src/vdom/diff.js
* https://todomvc.com/examples/vue/dist/#/
* https://github.com/tastejs/todomvc/blob/gh-pages/examples/vue/src/components/TodoItem.vue
