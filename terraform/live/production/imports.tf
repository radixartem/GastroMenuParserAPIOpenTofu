# ╔══════════════════════════════════════════════════════════╗
# ║  ОДНОКРАТНЫЙ ИМПОРТ СУЩЕСТВУЮЩЕЙ ИНФРАСТРУКТУРЫ        ║
# ║  Перед первым применением замените ID на реальные       ║
# ║  и раскомментируйте блоки.                              ║
# ║  После успешного `tofu apply` этот файл можно удалить.  ║
# ╚══════════════════════════════════════════════════════════╝

# import {
#   to = module.firewall["production"].hcloud_firewall.this
#   id = "111111"   # ID существующего файрвола
# }

# import {
#   to = module.volume["postgres"].hcloud_volume.this
#   id = "222222"   # ID существующего тома PostgreSQL
# }

# import {
#   to = module.server["gastro-prod"].hcloud_server.this
#   id = "333333"   # ID существующего сервера
# }

# import {
#   to = module.server["gastro-prod"].hcloud_volume_attachment.this[0]
#   id = "222222"   # ID тома (импорт volume attachment по volume_id)
# }