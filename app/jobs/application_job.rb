class ApplicationJob < ActiveJob::Base
  # デッドロックが起きたジョブを、自動で再試行します。
  # retry_on ActiveRecord::Deadlocked

  # 対象のレコードがもう存在しない場合は、たいていのジョブは無視しても問題ありません。
  # discard_on ActiveJob::DeserializationError
end
