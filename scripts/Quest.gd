class_name Quest
extends RefCounted
## Quest — a single quest: an ordered array of micro-task scene paths,
## then a BOSS fight at the end. Quests chain endlessly; each finished quest
## (boss defeated) raises quest_number → next difficulty (see GameManager).

var number: int = 1
var difficulty: float = 1.0
var tasks: Array[String] = []      # one scene path per micro-task
var boss_scene: String = ""        # scene path of the boss encounter

## How many micro-tasks remain before the boss.
func remaining() -> int:
	return tasks.size()