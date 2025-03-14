
class EditorComponent < Component
  attr_reactive :text

  def initialize
    @text = <<~MARKDOWN
# Todos

- [x] Finish my changes
- [ ] Push my commits to GitHub
- [ ] Open a pull request
- [x] @mentions, #refs, [links](), **formatting**, and <del>tags</del> supported
- [x] list syntax required (any unordered or ordered list supported)
- [ ] this is a complete item
- [ ] this is an incomplete item

## Table

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | centered      |   $12 |
| zebra stripes | are neat      |    $1 |

## Code

```ruby
class User
  def self.greeting
    puts 'Hello!!'
  end
end

User.greeting # => Hello!!
```
    MARKDOWN
  end

  def template
    <<~ERB
      <div style="display: flex; height: 90vh; padding-top: 2rem">
        <textarea style="width: 50%;" r-model="text"><%= text %></textarea>
        <div style="width: 50%; padding: 1rem">
          <%= JS.global[:markedWithHighlight].parse(text) %>
        </div>
      </div>
    ERB
  end
end
