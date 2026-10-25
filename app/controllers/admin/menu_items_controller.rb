module Admin
  # メニュー／価格の管理: 1画面で施術名と価格をその場で修正します（Turbo Stream）。
  class MenuItemsController < BaseController
    before_action :set_item, only: %i[update destroy toggle move_up move_down]

    def index
      @categories = MenuCategory.kept.ordered.includes(:menu_items)
    end

    def create
      category = MenuCategory.kept.find(params.dig(:menu_item, :menu_category_id))
      @item = category.menu_items.new(item_params)
      if @item.save
        respond_with_streams(
          turbo_stream.append(dom_id(category, :items), partial: "admin/menu_items/item", locals: { item: @item, saved: true }),
          turbo_stream.replace(dom_id(category, :new_item), partial: "admin/menu_items/new_form",
                               locals: { category: category, item: category.menu_items.new })
        )
      else
        respond_with_streams(
          turbo_stream.replace(dom_id(category, :new_item), partial: "admin/menu_items/new_form",
                               locals: { category: category, item: @item }),
          status: :unprocessable_entity
        )
      end
    end

    def update
      if @item.update(item_params)
        respond_with_streams(turbo_stream.replace(@item, partial: "admin/menu_items/item", locals: { item: @item, saved: true }))
      else
        respond_with_streams(turbo_stream.replace(@item, partial: "admin/menu_items/item", locals: { item: @item, saved: false }),
                             status: :unprocessable_entity)
      end
    end

    def destroy
      @item.discard!
      respond_with_streams(turbo_stream.remove(@item))
    end

    def toggle
      @item.update!(visible: !@item.visible?)
      respond_with_streams(turbo_stream.replace(@item, partial: "admin/menu_items/item", locals: { item: @item, saved: false }))
    end

    def move_up
      @item.move_up!
      respond_with_streams(items_list_stream(@item.menu_category))
    end

    def move_down
      @item.move_down!
      respond_with_streams(items_list_stream(@item.menu_category))
    end

    private

    def dom_id(*args) = ActionView::RecordIdentifier.dom_id(*args)

    def items_list_stream(category)
      turbo_stream.replace(dom_id(category, :items), partial: "admin/menu_items/items",
                           locals: { category: category.reload })
    end

    def set_item
      @item = MenuItem.find(params[:id])
    end

    def respond_with_streams(*streams, status: :ok)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: streams, status: status }
        format.html { redirect_to admin_menu_items_path }
      end
    end

    def item_params
      langs = Translatable::LOCALES
      keys = %i[name description].product(langs).map { |k, l| :"#{k}_#{l}" }
      params.require(:menu_item).permit(:price, :price_from, :visible, *keys)
    end
  end
end
