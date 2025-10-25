extends CanvasLayer

# Łapiemy nasze węzły ze sceny po nazwie
# Te ścieżki są poprawne dla struktury z Kroku 2
@onready var hearts_container = $HeartsContainer
@onready var energy_container = $EnergyContainer
@onready var coin_label = $CoinContainer/CoinLabel

func _ready():
	# Łączymy "krzyk" z "Mózgu" (GameStats) z funkcjami w tym skrypcie
	GameStats.lives_changed.connect(update_lives)
	GameStats.energy_changed.connect(update_energy)
	GameStats.coins_changed.connect(update_coins)
	
	# Ustawiamy startowe wartości
	update_lives(GameStats.lives)
	update_energy(GameStats.energy)
	update_coins(GameStats.coins)

# Ta funkcja odpali się, gdy "Mózg" krzyknie "lives_changed"
func update_lives(new_lives):
	var hearts = hearts_container.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = (i < new_lives) 

# Ta funkcja robi to samo dla energii
func update_energy(new_energy):
	var energy_drinks = energy_container.get_children()
	for i in range(energy_drinks.size()):
		energy_drinks[i].visible = (i < new_energy)

# Ta funkcja aktualizuje tekst licznika monet
func update_coins(new_coins):
	coin_label.text = "x" + str(new_coins)
