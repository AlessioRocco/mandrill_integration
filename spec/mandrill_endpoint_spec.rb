require 'spec_helper'

describe MandrillEndpoint do

  let(:payload_with_string) {
    '{"request_id": "12e12341523e449c3000001",
      "parameters": {
        "mandrill_api_key": "KqE5SjhclKAoTmUu5vV3nA"},
        "email": {
          "to": "spree@example.com, wombat@example.com",
          "from": "spree@example.com",
          "subject": "Order R123456 was shipped!",
          "template": "order_confirmation",
          "variables": {
            "customer.name": "John Smith",
            "order.total": "100.00",
            "order.tracking": "XYZ123"
          }
        }
      }'
  }

  let(:payload_with_parameters) {
    '{"request_id": "12e12341523e449c3000001",
      "parameters": {
        "mandrill_api_key": "KqE5SjhclKAoTmUu5vV3nA"},
        "email": {
          "to": [
            { "email": "spree@example.com" },
            { "email": "alessio.rocco.lt@gmail.com", "type": "cc" }
          ],
          "from": "spree@example.com",
          "subject": "Order R123456 was shipped!",
          "template": "order_confirmation",
          "variables": {
            "customer.name": "John Smith",
            "order.total": "100.00",
            "order.tracking": "XYZ123"
          }
        }
      }'
  }

  describe "when 'to' param is a string" do
    it "should respond to POST send_email" do
      VCR.use_cassette('mandrill_send_to_as_string') do
        post '/send_email', payload_with_string, auth
        expect(last_response.status).to eql 200
        expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
        expect(json_response["summary"]).to match /Sent 'Order R123456 was shipped!' email/
      end
    end
  end

  describe "when 'to' param is an array" do
    it "should respond to POST send_email" do
      VCR.use_cassette('mandrill_send_to_as_parameters') do
        post '/send_email', payload_with_parameters, auth
        expect(last_response.status).to eql 200
        expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
        expect(json_response["summary"]).to match /Sent 'Order R123456 was shipped!' email/
      end
    end
  end
end
