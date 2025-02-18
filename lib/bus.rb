class Bus

  @subscribtions = {}

  def self.subscribe(channel, &block)
    @subscribtions[channel] ||= []
    @subscribtions[channel] << block
  end    

 def self.publish(channel, payload)
  @subscribtions[channel]&.each do |handler|
    handler.call(payload)
  end
 end

 def self.clear
  @subscribtions = {}
 end
end


Bus.subscribe('test') do |payload|
 puts 'hello'
 puts payload
end

Bus.publish('test', {a: 1})
