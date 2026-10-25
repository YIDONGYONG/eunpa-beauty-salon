# 例外をメールで通知する軽量な仕組み（gem 追加なし。Rails.error は Rails 標準の例外フック）。
# ERROR_NOTIFY_EMAIL と SMTP_ADDRESS が両方あるときだけ有効。同じ種類の通知は THROTTLE 秒に1回まで。
class ErrorNotifier
  THROTTLE = 600
  @last_sent = {}

  class << self
    def enabled?
      Rails.env.production? && ENV["ERROR_NOTIFY_EMAIL"].present? && ENV["SMTP_ADDRESS"].present?
    end

    def report(error, handled:, severity:, context:, source: nil)
      return if handled || !enabled?
      return if throttled?(error.class.name)

      summary = { class: error.class.name, message: error.message.to_s.first(300), time: Time.current.iso8601,
                  backtrace: Array(error.backtrace).first(8) }
      ErrorMailer.notify(summary).deliver_later
    rescue StandardError => e
      Rails.logger.warn("[ErrorNotifier] failed: #{e.class}")
    end

    private

    def throttled?(key)
      now = Time.now.to_i
      return true if @last_sent[key] && now - @last_sent[key] < THROTTLE

      @last_sent[key] = now
      false
    end
  end
end

Rails.error.subscribe(ErrorNotifier)
