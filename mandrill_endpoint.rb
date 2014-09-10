Dir['./lib/**/*.rb'].each { |f| require f }

class MandrillEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  Honeybadger.configure do |config|
    config.api_key = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  helpers do
    def to_addr
      if @payload['email']['to'].is_a?(Array)
        @payload['email']['to']
      else
        @payload['email']['to'].to_s.split(',').map{|email| { email: email }}
      end
    end
  end

  post '/send_email' do
    # convert variables into Mandrill array / hash format.
    #
    if !(@payload.key? 'email')
      add_value :payload_inspect, @payload.inspect
      result 500, "No Email Key found in Payload"
    end

    global_merge_vars = @payload['email'].fetch('variables', []).map do |name, value|
      { 'name' => name, 'content' => value }
    end

    template = @payload['email']['template']
    from_addr = @payload['email']['sender_email'] || @payload['email']['from']
    from_name = @payload['email']['sender_name'] || from_addr
    subject = @payload['email']['subject']
    bcc_address = @payload['email']['bcc_address'] || ""

    # create Mandrill request
    #
    request_body = {
      key: @config['mandrill_api_key'],
      template_name: template,
      message: {
        from_email: from_addr,
        from_name: from_name,
        to: to_addr,
        bcc_address: bcc_address,
        subject: subject,
        global_merge_vars: global_merge_vars
      },
      template_content: [
        name: 'User 1',
        content: 'Content 1'
      ]

    }.to_json

    # send request to Mandrill API
    #
    response = HTTParty.post('https://mandrillapp.com/api/1.0/messages/send-template.json',
                     body: request_body,
                     timeout: 240,
                     headers: { 'Content-Type'   => 'application/json' })

    #ugly because it could be a hash or an array
    #https://mandrillapp.com/api/docs/messages.html
    response = [response.parsed_response].flatten.first
    reason = response['reject_reason'] || response.inspect

    if %w{sent queued}.include?(response['status'])
      set_summary "Sent '#{subject}' email to #{to_addr}"
      add_value :mandrill_message_id, response["_id"]
      process_result 200
    else
      set_summary "Failed to send '#{subject}' email to #{to_addr} - #{reason}"
      process_result 500
    end
  end
end
