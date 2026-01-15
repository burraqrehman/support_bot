# OpenAI configuration
# Make sure to set OPENAI_API_KEY in your environment variables
# For development, you can add it to config/credentials.yml.enc or use a .env file

require "openai"

if ENV["OPENAI_API_KEY"].present?
  Rails.logger.info "OpenAI API key configured"
else
  Rails.logger.warn "OPENAI_API_KEY not set. LLM features will not work."
end
