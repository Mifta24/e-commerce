class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i[edit update destroy]

  def index
    # left_joins supaya kategori yang belum punya produk tetap muncul (jumlahnya 0)
    @categories = Category.left_joins(:products)
                          .group("categories.id")
                          .select("categories.*, COUNT(products.id) AS jumlah_produk")
                          .order(:name)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: "Kategori berhasil dibuat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "Kategori berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # produk di dalamnya tidak ikut terhapus: kolom category_id-nya dikosongkan (dependent: :nullify)
    @category.destroy
    redirect_to admin_categories_path, notice: "Kategori berhasil dihapus.", status: :see_other
  end

  private

  def set_category
    @category = Category.find(params.expect(:id))
  end

  def category_params
    params.expect(category: [ :name ])
  end
end
