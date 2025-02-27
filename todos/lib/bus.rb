class Bus
  @subscriptions = {}

  def self.subscribe(channel, &block)
    @subscriptions[channel] ||= []
    @subscriptions[channel] << block
  end

  def self.publish(channel, payload)
   puts "Channel: #{channel}, payload: #{payload}"

   @subscriptions.each do |pattern, handlers|
      if channel.match?(pattern)
        handlers.each do |handler|
          handler.call(payload)
        end
      end
   end
  end

  def self.clear
   @subscriptions = {}
  end
end
