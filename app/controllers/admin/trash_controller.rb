module Admin
  # 削除した項目を元に戻す（復元）／完全に削除する画面
  class TrashController < BaseController
    def index
      @entries = Trash.entries
    end

    def restore
      record = Trash.find(params[:type], params[:id])
      record.undiscard!
      redirect_to admin_trash_index_path, notice: "되돌렸습니다."
    end

    def destroy
      Trash.find(params[:type], params[:id]).destroy
      redirect_to admin_trash_index_path, notice: "완전히 삭제했습니다.", status: :see_other
    end
  end
end
