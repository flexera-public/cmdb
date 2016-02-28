module Output
  def self.retry_timed(duration)
    t0 = Time.now
    t1 = t0 + duration
    loop do
      return if Time.now >= t1 || yield(t1 - Time.now)
    end
  end
end

And /^the output should (not )?include "(.*)"$/ do |negatory, message|
  if @command && !@command.captured_output.include?(message)
    Output.retry_timed(10) do |dt|
      if @command.captured_output.include?(message)
        true
      else
        @command.join(dt / 100)
        false
      end
    end
  end

  @output = @command.captured_output

  if negatory
    @output.should_not include(message)
  else
    @output.should include(message)
  end
end

And /^the output should have keys: (.*)$/ do |kvs|
  kvs = kvs.split(/;/)
  kvs = kvs.inject({}) { |h, kv| p = kv.split('=') ; h[p.first] = p.last ; h }

  mismatched = []
  kvs.each do |k, v|
    mismatched << k unless @output.include?(k + '=' + v)
  end
  mismatched.should be_empty
end
