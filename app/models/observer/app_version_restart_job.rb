class Observer::AppVersionRestartJob
  def initialize(cmd)
    @cmd = cmd
  end

  def perform
    system(@cmd)
    Rails.logger.info "execute CMD: #{@cmd}"
  end
end
