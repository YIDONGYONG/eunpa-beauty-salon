module Admin
  # イベント/バナー: タイトル・文言・期間を入力すると、期間中だけホームに表示されます。
  class EventsController < BaseController
    before_action :set_event, only: %i[edit update destroy toggle]

    def index
      @events = Event.kept.order(Arel.sql("ends_on IS NULL, ends_on DESC"), id: :desc)
    end

    def new
      @event = Event.new(starts_on: Date.current, ends_on: Date.current + 30)
    end

    def create
      @event = Event.new(event_params)
      if @event.save
        redirect_to admin_events_path, notice: "이벤트를 저장했습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to admin_events_path, notice: "이벤트를 수정했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.discard!
      redirect_to admin_events_path, notice: "이벤트를 삭제했습니다. (휴지통에서 되돌릴 수 있습니다)", status: :see_other
    end

    def toggle
      @event.update!(published: !@event.published?)
      redirect_to admin_events_path, notice: @event.published? ? "이벤트를 보이게 했습니다." : "이벤트를 숨겼습니다."
    end

    private

    def set_event
      @event = Event.kept.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:title_ko, :title_en, :message_ko, :message_en, :starts_on, :ends_on, :published)
    end
  end
end
