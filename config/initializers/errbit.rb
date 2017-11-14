Airbrake.configure do |config|
  config.host = 'https://errbitbit.herokuapp.com'
  config.project_id = 1
  config.project_key = ENV['ERRBIT_PROJECT_KEY'] || 'dummy'
end

Airbrake.add_filter(&:ignore!) unless ENV['ERRBIT_PROJECT_KEY']
