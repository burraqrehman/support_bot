class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    conversation = current_user.conversations.find(params[:conversation_id])

    conversation.messages.create!(role: "user", content: params[:content])

    # Placeholder: we’ll call the orchestrator in Step 9
    assistant_text = Chat::Orchestrator.new(
      user: current_user,
      conversation: conversation,
      message: params[:content]
    ).call

    conversation.messages.create!(role: "assistant", content: assistant_text)

    redirect_to chat_path
  end
end
