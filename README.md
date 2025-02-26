# vuerb

A web client framework to build reactive web app in Ruby with WASM.

## Example

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

See it live https://bhacaz.github.io/vuerb/

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
