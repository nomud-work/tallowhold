## Fully automatic battle, data-oriented: one manager steps every unit in
## plain arrays (no node or _process per unit). Seeded, so the same inputs
## always give the same battle. The view only reads state and drains events.
class_name BattleSim
extends RefCounted

enum Ev { HIT, HEAL, DEATH, BLAST, SHOT, SUMMON, SLAM }
enum Outcome { RUNNING, WON, LOST }

const DT := 1.0 / 60.0
const ARENA := Rect2(40, 96, 1200, 600)
const CELL := 32.0
const RETARGET_TICKS := 15
const MAX_SUMMONS := 24
const TIME_LIMIT := 120.0
const SLOW_FACTOR := 0.5

var rng := RandomNumberGenerator.new()
var units: Array[SimUnit] = []
var shots: Array[SimShot] = []
var events: Array = []  # [Ev, Vector2, float value, int team, extra]
var record_events := true
var mods: ArmyMods
var wave: WaveDef
var tick := 0
var time := 0.0
var outcome := Outcome.RUNNING
var alive_count: Array[int] = [0, 0]
var summons_alive: Array[int] = [0, 0]
var kills := 0
var peak_alive := 0
var _next_uid := 0
var _spawn_queue: Array = []  # [time, def_id]
var _grid_w := int(ARENA.size.x / CELL) + 1
var _grid_h := int(ARENA.size.y / CELL) + 1
var _grid: Array = []

func setup(army: Array[StringName], army_mods: ArmyMods, wave_def: WaveDef, battle_seed: int) -> void:
	rng.seed = battle_seed
	mods = army_mods
	wave = wave_def
	_grid.resize(_grid_w * _grid_h)
	for i in _grid.size():
		_grid[i] = []
	_spawn_army(army)
	_queue_wave()

func _spawn_army(army: Array[StringName]) -> void:
	for id in army:
		var def := Catalog.unit(id)
		var cx := _formation_x(def.role)
		var cy := rng.randf_range(ARENA.get_center().y - 170, ARENA.get_center().y + 170)
		for i in def.squad_size:
			var p := Vector2(cx + rng.randf_range(-28, 28), cy + rng.randf_range(-40, 40))
			_add_unit(def, 0, p, false)

func _formation_x(role: int) -> float:
	match role:
		UnitDef.Role.TANK:
			return 470.0
		UnitDef.Role.MELEE, UnitDef.Role.EXPLODER:
			return 420.0
		UnitDef.Role.SUMMONER:
			return 300.0
		UnitDef.Role.HEALER:
			return 260.0
	return 330.0

func _queue_wave() -> void:
	# Enemies arrive in three pulses so the screen fills up instead of popping in.
	var order: Array = []
	for k in wave.enemy_ids.size():
		for n in wave.counts[k]:
			order.append(wave.enemy_ids[k])
	for i in order.size():
		var pulse := i % 3
		var t := pulse * 2.5 + rng.randf_range(0.0, 1.2)
		if Catalog.unit(order[i]).role == UnitDef.Role.BOSS:
			t = 1.0
		_spawn_queue.append([t, order[i]])
	_spawn_queue.sort_custom(func(a, b): return a[0] < b[0])

func _add_unit(def: UnitDef, team: int, p: Vector2, summon: bool) -> SimUnit:
	var u := SimUnit.new()
	u.uid = _next_uid
	_next_uid += 1
	u.def = def
	u.team = team
	u.pos = p
	u.is_summon = summon
	u.lane_bias = rng.randf_range(-0.35, 0.35)
	u.facing = 1.0 if team == 0 else -1.0
	if team == 0:
		u.max_hp = def.hp * mods.hp_mult(def)
		u.damage = def.damage * mods.damage_mult(def)
		u.attack_interval = def.attack_interval / mods.haste
		u.speed = def.speed * mods.haste
		u.shield = mods.shield
	else:
		u.max_hp = def.hp * wave.hp_scale
		u.damage = def.damage * wave.damage_scale
		u.attack_interval = def.attack_interval
		u.speed = def.speed
	u.hp = u.max_hp
	u.attack_cd = rng.randf_range(0.1, u.attack_interval)
	u.summon_cd = def.summon_interval * 0.5
	units.append(u)
	alive_count[team] += 1
	if summon:
		summons_alive[team] += 1
	peak_alive = maxi(peak_alive, alive_count[0] + alive_count[1])
	return u

func step() -> void:
	if outcome != Outcome.RUNNING:
		return
	tick += 1
	time += DT
	_release_spawns()
	_rebuild_grid()
	for u in units:
		if u.alive:
			_step_unit(u)
	_separate()
	_step_shots()
	if tick % 120 == 0:
		_compact()
	_check_outcome()

func _release_spawns() -> void:
	while not _spawn_queue.is_empty() and _spawn_queue[0][0] <= time:
		var e: Array = _spawn_queue.pop_front()
		var def := Catalog.unit(e[1])
		var y := rng.randf_range(ARENA.get_center().y - 230, ARENA.get_center().y + 230)
		if def.role == UnitDef.Role.BOSS:
			y = ARENA.get_center().y
		_add_unit(def, 1, Vector2(ARENA.end.x - rng.randf_range(60, 200), y), false)

func _step_unit(u: SimUnit) -> void:
	u.age += DT
	u.flash = maxf(u.flash - DT, 0.0)
	var slowed := u.slow_t > 0.0
	u.slow_t = maxf(u.slow_t - DT, 0.0)
	u.attack_cd -= DT * (0.6 if slowed else 1.0)
	if u.def.summon_interval > 0.0:
		u.summon_cd -= DT
		if u.summon_cd <= 0.0:
			u.summon_cd = u.def.summon_interval
			_summon(u)
	if u.target == null or not u.target.alive or (tick + u.uid) % RETARGET_TICKS == 0:
		u.target = _nearest_enemy(u)
	var t := u.target
	if t == null:
		return
	var to := t.pos - u.pos
	var dist := to.length()
	u.facing = signf(to.x) if absf(to.x) > 1.0 else u.facing
	var reach := u.def.attack_range + (u.def.radius + t.def.radius if u.def.attack_range < 40.0 else 0.0)
	var hold := reach
	if u.def.role == UnitDef.Role.HEALER:
		hold = u.def.attack_range + 30.0
	if dist > hold:
		var dir := to / maxf(dist, 0.001)
		dir = (dir + Vector2(-dir.y, dir.x) * u.lane_bias).normalized()
		u.pos += dir * u.speed * (SLOW_FACTOR if slowed else 1.0) * DT
	if u.attack_cd <= 0.0:
		if u.def.role == UnitDef.Role.HEALER:
			if _heal(u):
				u.attack_cd = u.attack_interval
		elif dist <= reach:
			u.attack_cd = u.attack_interval
			_attack(u, t)

func _attack(u: SimUnit, t: SimUnit) -> void:
	if u.def.role == UnitDef.Role.BOSS:
		_blast(u.pos, u.def.blast_radius, u.def.blast_damage * wave.damage_scale, u.team, Ev.SLAM)
	if u.def.projectile_speed > 0.0:
		var s := SimShot.new()
		s.pos = u.pos + Vector2(0, -u.def.radius)
		s.aim = t.pos
		s.target = t
		s.damage = u.damage
		s.speed = u.def.projectile_speed
		s.team = u.team
		s.color = u.def.color
		if u.def.role == UnitDef.Role.SLOWER:
			s.slow = u.def.support_power * mods.slow_power
		shots.append(s)
		_emit(Ev.SHOT, s.pos, 0.0, u.team, u.def.color)
	else:
		deal_damage(t, u.damage, u.team)

func _heal(u: SimUnit) -> bool:
	var best: SimUnit = null
	var best_ratio := 0.98
	var r2 := (u.def.attack_range + 20.0) * (u.def.attack_range + 20.0)
	for a in units:
		if a.alive and a.team == u.team and a.pos.distance_squared_to(u.pos) <= r2:
			var ratio := a.hp / a.max_hp
			if ratio < best_ratio:
				best_ratio = ratio
				best = a
	if best == null:
		return false
	var amount := u.def.support_power * mods.heal_power
	best.hp = minf(best.hp + amount, best.max_hp)
	_emit(Ev.HEAL, best.pos, amount, u.team, u.pos)
	return true

func _summon(u: SimUnit) -> void:
	var sdef := Catalog.unit(u.def.summon_id)
	var n := u.def.summon_count + (mods.summon_bonus if u.team == 0 else 0)
	for i in n:
		if summons_alive[u.team] >= MAX_SUMMONS:
			return
		var p := u.pos + Vector2(rng.randf_range(-24, 24), rng.randf_range(-24, 24))
		_add_unit(sdef, u.team, p, true)
		_emit(Ev.SUMMON, p, 0.0, u.team, sdef.color)

## The one damage entry point: shields first, then hp, then death handling.
func deal_damage(t: SimUnit, amount: float, source_team: int) -> void:
	if not t.alive or amount <= 0.0 or t.team == source_team:
		return
	var left := amount
	if t.shield > 0.0:
		var soak := minf(t.shield, left)
		t.shield -= soak
		left -= soak
	t.hp -= left
	t.flash = 0.12
	_emit(Ev.HIT, t.pos, amount, t.team, t.def.radius)
	if t.hp <= 0.0:
		_kill(t)

func _kill(t: SimUnit) -> void:
	t.alive = false
	t.target = null
	alive_count[t.team] -= 1
	if t.is_summon:
		summons_alive[t.team] -= 1
	if t.team == 1:
		kills += 1
	_emit(Ev.DEATH, t.pos, t.def.radius, t.team, t.def.color)
	if t.def.role == UnitDef.Role.EXPLODER:
		var bp := mods.blast_power if t.team == 0 else 1.0
		_blast(t.pos, t.def.blast_radius * (1.0 + (bp - 1.0) * 0.5), t.def.blast_damage * bp, t.team, Ev.BLAST)

func _blast(at: Vector2, radius: float, amount: float, team: int, kind: int) -> void:
	_emit(kind, at, radius, team, null)
	var r2 := radius * radius
	# Collect first: deal_damage can chain more blasts and append to units.
	var hit: Array[SimUnit] = []
	for o in units:
		if o.alive and o.team != team and o.pos.distance_squared_to(at) <= r2:
			hit.append(o)
	for o in hit:
		deal_damage(o, amount, team)

func _nearest_enemy(u: SimUnit) -> SimUnit:
	var best: SimUnit = null
	var best_d := INF
	for o in units:
		if o.alive and o.team != u.team:
			var d := o.pos.distance_squared_to(u.pos)
			if d < best_d:
				best_d = d
				best = o
	return best

func _rebuild_grid() -> void:
	for c in _grid:
		c.clear()
	for u in units:
		if u.alive:
			_grid[_cell_index(u.pos)].append(u)

func _cell_index(p: Vector2) -> int:
	var cx := clampi(int((p.x - ARENA.position.x) / CELL), 0, _grid_w - 1)
	var cy := clampi(int((p.y - ARENA.position.y) / CELL), 0, _grid_h - 1)
	return cy * _grid_w + cx

## Soft push-apart between overlapping units using the grid, then clamp.
func _separate() -> void:
	for u in units:
		if not u.alive:
			continue
		var cx := clampi(int((u.pos.x - ARENA.position.x) / CELL), 0, _grid_w - 1)
		var cy := clampi(int((u.pos.y - ARENA.position.y) / CELL), 0, _grid_h - 1)
		for gy in range(maxi(cy - 1, 0), mini(cy + 2, _grid_h)):
			for gx in range(maxi(cx - 1, 0), mini(cx + 2, _grid_w)):
				for o: SimUnit in _grid[gy * _grid_w + gx]:
					if o.uid <= u.uid or not o.alive:
						continue
					var d := o.pos - u.pos
					var min_d := (u.def.radius + o.def.radius) * 0.9
					var l2 := d.length_squared()
					if l2 < min_d * min_d:
						var l := sqrt(l2)
						var n := d / l if l > 0.001 else Vector2(1, 0).rotated(float(u.uid))
						var push := (min_d - l) * 0.5
						# Heavier (bigger) units get pushed less.
						var wu := o.def.radius / (u.def.radius + o.def.radius)
						u.pos -= n * push * wu * 2.0
						o.pos += n * push * (1.0 - wu) * 2.0
		u.pos = u.pos.clamp(ARENA.position + Vector2(u.def.radius, u.def.radius), ARENA.end - Vector2(u.def.radius, u.def.radius))

func _step_shots() -> void:
	for s in shots:
		if not s.alive:
			continue
		if s.target != null and s.target.alive:
			s.aim = s.target.pos
		var to := s.aim - s.pos
		var l := to.length()
		var stepd := s.speed * DT
		if l <= stepd + 4.0:
			s.alive = false
			var hit_t := s.target
			s.target = null
			if hit_t != null and hit_t.alive:
				deal_damage(hit_t, s.damage, s.team)
				if s.slow > 0.0:
					hit_t.slow_t = maxf(hit_t.slow_t, s.slow)
		else:
			s.pos += to / l * stepd
	if tick % 30 == 0:
		shots = shots.filter(func(s): return s.alive)

func _compact() -> void:
	units = units.filter(func(u): return u.alive)

func _check_outcome() -> void:
	if alive_count[0] <= 0:
		outcome = Outcome.LOST
	elif alive_count[1] <= 0 and _spawn_queue.is_empty():
		outcome = Outcome.WON
	elif time >= TIME_LIMIT:
		outcome = Outcome.LOST

func _emit(kind: int, at: Vector2, value: float, team: int, extra: Variant) -> void:
	if record_events:
		events.append([kind, at, value, team, extra])

## Runs the whole battle without rendering (tests and the balance runner).
func run_to_end(max_ticks: int = 60 * 130) -> int:
	record_events = false
	while outcome == Outcome.RUNNING and tick < max_ticks:
		step()
	return outcome

## Breaks SimUnit <-> target reference cycles so RefCounted memory is freed.
func dispose() -> void:
	for u in units:
		u.target = null
	for s in shots:
		s.target = null
	units.clear()
	shots.clear()
	events.clear()

func pending_spawns() -> int:
	return _spawn_queue.size()
