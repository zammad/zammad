class Observer::AppVersionRestartJob
  def initialize(cmd)
    @cmd = cmd
  end

  def perform
    output = `#{@cmd}`
    Rails.logger.info "CMD: #{@cmd} -> #{output}"
  end
end
