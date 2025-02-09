require 'sinatra/base'
require 'http'
require 'json'
require 'dotenv/load'

module Chatbot 
  class ChatbotServer < Sinatra::Base
    def initialize
      super
      @openai_api_key = ENV['OPENAI_API_KEY']
      @chat_model = 'gpt-4'
    end

    # Move chat_with_openai to be a helper method
    helpers do
      def chat_with_openai(prompt)
        url = 'https://api.openai.com/v1/chat/completions'
        headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{@openai_api_key}" }
        body = {
          model: 'gpt-4',
          messages: [
            { role: 'system', content: 'You are a helpful assistant.' },
            { role: 'user', content: prompt }
          ],
          max_tokens: 150
        }
      
        response = HTTP.headers(headers).post(url, json: body)
        return JSON.parse(response.body.to_s)['choices'][0]['message']['content'] if response.status.success?
      
        "Error: #{response.status} - #{response.body.to_s}"
      end
    end

    # Configure server settings
    configure do
      port = ENV['PORT'] || 4567  # Use PORT from .env or default to 4567
      set :port, port
      set :bind, '0.0.0.0'
      
      # Enable CORS
      enable :cross_origin
    end

    # CORS preflight
    options "*" do
      response.headers["Allow"] = "GET, POST, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
      response.headers["Access-Control-Allow-Origin"] = "*"
      200
    end

    before do
      response.headers['Access-Control-Allow-Origin'] = '*'
    end

    # Define routes
    get '/' do
      'Chatbot Server is running!'
    end

    post '/chat' do
      request_payload = JSON.parse(request.body.read)
      prompt = request_payload['prompt']
      content_type :json
      { reply: chat_with_openai(prompt) }.to_json
    end

    # Class method to start the server
    def self.run_server
      begin
        run!
      rescue Errno::EADDRINUSE
        puts "\nError: Port 4567 is already in use."
        puts "Please either:"
        puts "1. Stop the other server running on port 4567"
        puts "2. Or use a different port by setting SINATRA_PORT environment variable"
        puts "\nTo find and stop the existing server:"
        puts "lsof -i :4567     # Find the process"
        puts "kill -9 <PID>     # Stop it using the process ID\n"
        exit(1)
      end
    end
  end
end


# Testing example: 
# 
# Test the server is running
# curl http://localhost:4567

# Test the chat endpoint
# curl -X POST http://localhost:4567/chat \
#   -H "Content-Type: application/json" \
#   -d '{"prompt":"Hello, how are you?"}'