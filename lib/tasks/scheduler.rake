namespace :scheduler do
  task send_alerts: :environment do
    SendAlertsJob.new.perform_now
  end
end
