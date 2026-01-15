class DocumentChunk < ApplicationRecord
  belongs_to :document

  # Decode embedding vector if pgvector is available
  def embedding_vector
    return nil unless embedding.present?
    return embedding if embedding.is_a?(Array)
    
    # Try to decode if it's a string representation
    if embedding.is_a?(String)
      if embedding.start_with?('[')
        JSON.parse(embedding) rescue nil
      elsif defined?(PgVector) && PgVector.respond_to?(:decode)
        PgVector.decode(embedding)
      else
        nil
      end
    else
      embedding
    end
  rescue StandardError
    nil
  end
end
