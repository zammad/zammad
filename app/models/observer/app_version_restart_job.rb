class Observer::AppVersionRestartJob
  def initialize(cmd)
    @cmd = cmd
  end

  def perform
    Rails.logger.info "executing CMD: #{@cmd}"
    system(@cmd)
    Rails.logger.info "executed CMD: #{@cmd}"
  end
end
