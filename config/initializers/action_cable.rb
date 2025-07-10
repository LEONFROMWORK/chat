# Action Cable 연결 유지를 위한 설정
Rails.application.config.action_cable.connection_monitor_stale_threshold = 60.seconds
Rails.application.config.action_cable.connection_monitor_ping_interval = 3.seconds

# WebSocket keep-alive 설정
Rails.application.config.action_cable.disable_request_forgery_protection = false
Rails.application.config.action_cable.worker_pool_size = 4