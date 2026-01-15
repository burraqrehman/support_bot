class EmbeddingService
  # OpenAI's text-embedding-3-small model produces 1536-dimensional vectors
  EMBEDDING_MODEL = "text-embedding-3-small"
  EMBEDDING_DIMENSIONS = 1536

  def self.call(text)
    new.call(text)
  end

  def call(text)
    return nil if text.blank?

    response = client.embeddings(
      parameters: {
        model: EMBEDDING_MODEL,
        input: text
      }
    )

    response.dig("data", 0, "embedding")
  rescue StandardError => e
    Rails.logger.error "EmbeddingService error: #{e.message}"
    raise
  end

  private

  def client
    @client ||= OpenAI::Client.new(access_token: api_key)
  end

  def api_key
    ENV.fetch("OPENAI_API_KEY") do
      raise "OPENAI_API_KEY environment variable is required"
    end
  end
end
