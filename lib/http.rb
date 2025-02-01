# frozen_string_literal: true

require 'js'

# resp = JS.global.fetch('https://httpbin.org/anything').await
# puts resp.text.await

class Http
  class << self
    def get(url)
      resp = JS.global.fetch(url).await
      resp.json.await
    end
  end
end
