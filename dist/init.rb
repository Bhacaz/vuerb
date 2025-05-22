app_name = ARGV[0]

raise "Please provide an app name" if app_name.nil? || app_name.empty?

raise "App already exists" if Dir.exist?(app_name)

index_html = <<~HTML
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>VueRB</title>
        <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
        <link rel="stylesheet" href="https://matcha.mizu.sh/matcha.css">
        <script src="https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.1/dist/browser.script.iife.js"></script>
        <script type="text/ruby" data-eval="async" src="https://raw.githubusercontent.com/Bhacaz/vuerb/refs/tags/v0.1.1/dist/vuerb.rb"></script>
    </head>
    <body>
        <div style="padding-top: 5rem; text-align: center" id="app">Loading...</div>
    </body>
</html>
HTML

app_rb = <<~RUBY
# frozen_string_literal: true

require_relative 'components/counter_component'

class App < Component
  def template
    <<-ERB
      <div r-source="Counter"></div>
    ERB
  end
end
RUBY

counter_rb = <<~RUBY
# frozen_string_literal: true

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
RUBY

Dir.mkdir(app_name)
Dir.chdir(app_name) do
  Dir.mkdir('components')
  File.write('index.html', index_html)
  File.write('app.rb', app_rb)
  File.write('components/counter_component.rb', counter_rb)
end
