module Admin
  class MenuCategoriesController < BaseController
    before_action :set_category, only: %i[update destroy toggle move_up move_down]

    def create
      @category = MenuCategory.new(category_params)
      if @category.save
        respond_with_streams(categories_stream,
                             turbo_stream.replace("new_category", partial: "admin/menu_categories/new_form",
                                                                  locals: { category: MenuCategory.new }))
      else
        respond_with_streams(turbo_stream.replace("new_category", partial: "admin/menu_categories/new_form",
                                                                  locals: { category: @category }),
                             status: :unprocessable_entity)
      end
    end

    def update
      if @category.update(category_params)
        respond_with_streams(head_stream(saved: true))
      else
        respond_with_streams(head_stream(saved: false), status: :unprocessable_entity)
      end
    end

    def destroy
      @category.destroy
      respond_with_streams(categories_stream)
    end

    def toggle
      @category.update!(visible: !@category.visible?)
      respond_with_streams(head_stream(saved: false))
    end

    def move_up
      @category.move_up!
      respond_with_streams(categories_stream)
    end

    def move_down
      @category.move_down!
      respond_with_streams(categories_stream)
    end

    private

    def head_stream(saved:)
      turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@category, :head),
                           partial: "admin/menu_categories/head", locals: { category: @category, saved: saved })
    end

    def categories_stream
      turbo_stream.update("categories", partial: "admin/menu_items/categories",
                                         locals: { categories: MenuCategory.ordered.includes(:menu_items) })
    end

    def set_category
      @category = MenuCategory.find(params[:id])
    end

    def respond_with_streams(*streams, status: :ok)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: streams, status: status }
        format.html { redirect_to admin_menu_items_path }
      end
    end

    def category_params
      params.require(:menu_category).permit(:name_ko, :name_en, :name_vi, :name_ja, :visible)
    end
  end
end
