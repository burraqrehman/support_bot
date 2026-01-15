class ChatController < ApplicationController
  before_action :authenticate_user!

  def show
    @conversation = current_user.conversations.order(created_at: :desc).first ||
      current_user.conversations.create!(title: "Support Chat")

    @messages = @conversation.messages.order(:created_at)
  end
end
