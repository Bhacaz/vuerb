class Bus

  @subscribtions = {}

  def self.subscribe(channel, &block)
    @subscribtions[channel] ||= []
    @subscribtions[channel] << block
  end    

 def self.publish(channel, payload)
  puts "Channel: #{channel}, payload: #{payload}"
  @subscribtions[channel]&.each do |handler|
    handler.call(payload)
  end
 end

 def self.clear
  @subscribtions = {}
 end
end
