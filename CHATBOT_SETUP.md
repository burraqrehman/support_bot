# Support Bot - RAG Chatbot Setup Guide

This application implements a Retrieval-Augmented Generation (RAG) chatbot that can answer questions based on your application's knowledge base.

## Features

- **Document Ingestion**: Add documents to the knowledge base via the web interface
- **Semantic Search**: Uses vector embeddings (pgvector) for intelligent document retrieval
- **LLM Integration**: Uses OpenAI GPT-4o-mini for generating responses
- **Conversation History**: Maintains context across multiple messages
- **Modern UI**: Clean, responsive chat interface

## Prerequisites

1. **PostgreSQL with pgvector extension** (optional but recommended)
   - For macOS: `brew install pgvector`
   - For Docker: Use a pgvector-enabled PostgreSQL image
   - The app will fall back to text search if pgvector isn't available

2. **OpenAI API Key**
   - Sign up at https://platform.openai.com/
   - Get your API key from https://platform.openai.com/api-keys

## Setup Steps

### 1. Install Dependencies

```bash
bundle install
```

### 2. Set Environment Variables

Create a `.env` file in the project root (or use Rails credentials):

```bash
OPENAI_API_KEY=your_openai_api_key_here
```

Or add to `config/credentials.yml.enc`:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add:
```yaml
openai_api_key: your_openai_api_key_here
```

Then update the services to use `Rails.application.credentials.openai_api_key` instead of `ENV["OPENAI_API_KEY"]`.

### 3. Run Database Migrations

```bash
bin/rails db:migrate
```

Note: If pgvector isn't installed, the migration will skip the vector column creation but still work with text search.

### 4. Start the Server

```bash
bin/dev
```

Or:

```bash
bin/rails server
```

## Usage

### Adding Documents to Knowledge Base

1. Navigate to `/documents` (or click "Knowledge Base" in the chat header)
2. Click "Add Document"
3. Fill in:
   - **Title**: A descriptive title
   - **Source**: Where the document came from (optional)
   - **URL**: Original URL if applicable (optional)
   - **Content**: The actual text content
4. Click "Ingest Document"

The system will:
- Chunk the content into smaller pieces
- Generate embeddings for each chunk (if pgvector is available)
- Store everything in the database

### Using the Chatbot

1. Navigate to `/chat` (or the root URL)
2. Type your question in the input field
3. The bot will:
   - Search the knowledge base for relevant information
   - Use that context to generate an accurate answer
   - Display the response in the chat interface

### Example Questions

- "How do I reset my password?"
- "What are the main features of this application?"
- "How do I contact support?"

## Architecture

### Services

- **`EmbeddingService`**: Generates vector embeddings using OpenAI's text-embedding-3-small model
- **`SemanticSearchService`**: Finds relevant document chunks using vector similarity or text search
- **`DocumentIngestionService`**: Processes documents, chunks them, and generates embeddings
- **`Chat::Orchestrator`**: Coordinates the RAG flow (retrieval + generation)

### Models

- **`Document`**: Stores source documents
- **`DocumentChunk`**: Stores chunks with optional embeddings
- **`Conversation`**: User conversation sessions
- **`Message`**: Individual messages in conversations

## Troubleshooting

### "OPENAI_API_KEY environment variable is required"

Make sure you've set the `OPENAI_API_KEY` environment variable or added it to Rails credentials.

### "pgvector not available"

The app will work with text search fallback, but for best results, install pgvector:
- macOS: `brew install pgvector && brew services restart postgresql@16`
- Then re-run migrations: `bin/rails db:migrate:redo`

### Embeddings not being generated

Check:
1. OpenAI API key is set correctly
2. You have API credits/quota
3. Check Rails logs for errors

### Chat responses are slow

- Consider caching embeddings
- Use a faster LLM model (e.g., gpt-3.5-turbo instead of gpt-4o-mini)
- Reduce the number of chunks retrieved (default is 5)

## Customization

### Change LLM Model

Edit `app/services/chat/orchestrator.rb`:

```ruby
model: "gpt-3.5-turbo"  # Faster, cheaper
# or
model: "gpt-4"  # More capable, slower, more expensive
```

### Adjust Chunk Size

Edit `app/services/knowledge/chunker.rb`:

```ruby
def self.call(text, max_chars: 2000)  # Increase chunk size
```

### Change Search Parameters

Edit `app/services/chat/orchestrator.rb`:

```ruby
relevant_chunks = SemanticSearchService.call(@message, limit: 10)  # More context
```

## Production Considerations

1. **API Rate Limits**: Implement rate limiting for OpenAI API calls
2. **Caching**: Cache embeddings and common queries
3. **Error Handling**: Add retry logic for API failures
4. **Monitoring**: Track API usage and costs
5. **Security**: Ensure documents are properly sanitized before ingestion
6. **Background Jobs**: Move document ingestion to background jobs for large documents

## License

[Your License Here]
