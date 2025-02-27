# vuerb

A web client framework to build reactive web app in Ruby with WebAssembly.

## Concept

The framwork use only standard Ruby libs wichi include `ERB` to render HTML.
The render is then morphed to the actual DOM.

It need less directive like `v-if` or `v-for` because it can be done using Ruby and `ERB`.

Some directive is still needed to register to listener.

## Usage

The classic simple counter looks like this.

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

More [example](https://github.com/Bhacaz/vuerb/blob/gh-pages/README.md).

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
     <input r-model="message">
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
 <div data-key=<% todo.id %>>
  <h1><%= todo.title %></h1>
 </div>
<% end %>
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
