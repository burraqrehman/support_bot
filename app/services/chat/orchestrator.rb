module Chat
  class Orchestrator
    SYSTEM_PROMPT = <<~PROMPT
      You are a helpful support assistant for this application. Your role is to answer user questions
      based on the knowledge base provided. Use the context from the knowledge base to provide accurate,
      helpful answers. If the context doesn't contain enough information to answer the question, say so
      politely and suggest what information might be helpful.

      Always be concise, friendly, and professional. Cite specific information from the knowledge base
      when relevant.
    PROMPT

    def initialize(user:, conversation:, message:)
      @user = user
      @conversation = conversation
      @message = message
    end

    def call
      # Retrieve relevant context from knowledge base
      relevant_chunks = SemanticSearchService.call(@message, limit: 5)
      context = build_context(relevant_chunks)

      # Build conversation history
      conversation_history = build_conversation_history

      # Generate response using LLM
      generate_response(context, conversation_history)
    rescue StandardError => e
      Rails.logger.error "Chat::Orchestrator error: #{e.message}\n#{e.backtrace.join("\n")}"
      "I apologize, but I encountered an error while processing your request. Please try again."
    end

    private

    def build_context(chunks)
      return "No relevant information found in the knowledge base." if chunks.empty?

      chunks.map.with_index(1) do |chunk, idx|
        "[Document #{chunk.document_id}, Chunk #{idx}]:\n#{chunk.content}\n"
      end.join("\n---\n\n")
    end

    def build_conversation_history
      # Get last 10 messages for context (excluding the current one)
      @conversation.messages
        .order(created_at: :desc)
        .limit(10)
        .reverse
        .map { |msg| { role: msg.role, content: msg.content } }
    end

    def generate_response(context, conversation_history)
      messages = [
        { role: "system", content: SYSTEM_PROMPT },
        *conversation_history,
        { role: "user", content: build_user_message(context) }
      ]

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: messages,
          temperature: 0.7,
          max_tokens: 1000
        }
      )

      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error "LLM API error: #{e.message}"
      raise
    end

    def build_user_message(context)
      <<~MESSAGE
        Context from knowledge base:
        #{context}

        User question: #{@message}
      MESSAGE
    end

    def client
      @client ||= OpenAI::Client.new(access_token: api_key)
    end

    def api_key
      ENV.fetch("OPENAI_API_KEY") do
        raise "OPENAI_API_KEY environment variable is required"
      end
    end
  end
end
