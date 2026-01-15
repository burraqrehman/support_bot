class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @documents = Document.order(created_at: :desc).limit(50)
  end

  def new
    @document = Document.new
  end

  def create
    @document = DocumentIngestionService.call(document_params)

    if @document.persisted?
      redirect_to documents_path, notice: "Document ingested successfully with #{@document.document_chunks.count} chunks."
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    @document ||= Document.new
    flash.now[:alert] = "Error ingesting document: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def show
    @document = Document.find(params[:id])
    @chunks = @document.document_chunks.order(:created_at)
  end

  def destroy
    @document = Document.find(params[:id])
    @document.destroy
    redirect_to documents_path, notice: "Document deleted successfully."
  end

  private

  def document_params
    params.require(:document).permit(:title, :source, :url, :content, :raw_content)
  end
end
