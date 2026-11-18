class CategoriesController < ApplicationController
  # unutk mengatur kategori sebelum tindakan tertentu dijalankan, seperti show, edit, update, dan destroy. Hal ini memastikan bahwa kategori yang sesuai diambil dari database berdasarkan ID yang diberikan dalam parameter.
  before_action :set_category, only: %i[ show edit update destroy ]
  allow_unauthenticated_access only: %i[index show]   # publik boleh lihat
  before_action :require_admin, except: %i[index show] # sisanya admin saja
  
  # GET /categories or /categories.json
  def index
    @categories = Category.includes(:products).order(:name)
  end

  # GET /categories/1 or /categories/1.json
  def show
    @products = @category.products.order(created_at: :desc)
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # GET /categories/1/edit
  def edit
  end

  # POST /categories or /categories.json
  def create
    @category = Category.new(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: "Kategori berhasil dibuat." }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @category.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to @category, notice: "Kategori berhasil diperbarui.", status: :see_other }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @category.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    @category.destroy!

    respond_to do |format|
      format.html { redirect_to categories_path, notice: "Kategori berhasil dihapus.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def category_params
      params.expect(category: [ :name ])
    end
end
