#!/usr/bin/env python3
"""
eco_sim.py — Primordia ecological simulation tool.
Simulates agent dynamics, diagnoses problems, corrects GDScript parameters.
No external deps (stdlib only).
"""

import random
import re
import os
import copy
from typing import NamedTuple

# ── Tunable parameters (mirrored from GDScript) ──────────────────────────────

PARAMS = {
    # Bacterium
    "bact_metabolism":        0.008,
    "bact_uptake":            0.018,
    "bact_energy_gain_mult":  1.2,
    "bact_o2_used_ratio":     0.15,
    "bact_toxin_prod_ratio":  0.4,
    "bact_division_threshold":1.0,
    "bact_max_age":           3000,
    "bact_toxin_death_base":  0.4,
    "bact_toxin_death_chance":0.18,
    "bact_o2_death_thresh":   0.08,
    "bact_o2_death_chance":   2.0,
    # Protozoa
    "proto_metabolism":       0.002,
    "proto_max_age":          8000,
    "proto_prey_kill_period": 50,   # ticks between kills if bacteria > 5
    "proto_energy_gain":      0.7,  # fraction of prey energy
    "proto_division_energy":  1.2,  # energy to reproduce
    # Plant
    "plant_phot_rate":        0.08,
    "plant_nutrient_frac":    0.3,
    "plant_o2_frac":          0.2,
    "plant_toxin_frac":       0.15,
    "plant_metabolism":       0.002,
    "plant_max_age":          8000,
    "plant_light_thresh":     0.15,
    "plant_div_period":       200,  # avg ticks between plant spreads
    "plant_div_energy_thresh":2.0,
    # Fungi
    "fungi_nutrient_uptake":  0.02,
    "fungi_uptake_cond":      0.3,  # only if nutrients < this
    "fungi_metabolism":       0.008,
    "fungi_max_age":          6000,
    # Environment regen (per chunk per tick) — from WorldGrid BIOME_REGEN / 30
    "grass_nutrients_regen":  0.06  / 30,
    "grass_o2_regen":         0.040 / 30,
    "grass_o2_cap":           0.45,
    "earth_nutrients_regen":  0.025 / 30,
    "earth_o2_regen":         0.010 / 30,
    "earth_o2_cap":           0.26,
    "wood_nutrients_regen":   0.09  / 30,
    "wood_o2_regen":          0.055 / 30,
    "wood_o2_cap":            0.55,
    # Toxin passive decay (WorldGrid: 0.002 every 30 ticks)
    "toxin_decay":            0.002 / 30,
    # Diffusion rate between chunks
    "diffuse_rate":           0.10,
    # Per-type SOFT_CAP fraction (prevents any single type from monopolizing)
    "plant_softcap_frac":     0.20,  # plants <= 20% of SOFT_CAP
    "bact_softcap_frac":      0.70,  # bacteria <= 70% of SOFT_CAP
}

SOFT_CAP = 8000


# ── Biome chunk definitions ───────────────────────────────────────────────────

class Chunk:
    def __init__(self, biome: str, nutrients: float, o2: float, toxins: float, light: float,
                 nutrients_regen: float, o2_regen: float, o2_cap: float, nutrients_cap: float):
        self.biome = biome
        self.nutrients = nutrients
        self.o2 = o2
        self.toxins = toxins
        self.light = light
        self.nutrients_regen = nutrients_regen
        self.o2_regen = o2_regen
        self.o2_cap = o2_cap
        self.nutrients_cap = nutrients_cap


def make_chunks(p: dict) -> list:
    chunks = []
    for _ in range(4):  # 4x GRASS
        chunks.append(Chunk("GRASS",
            nutrients=0.6, o2=0.23, toxins=0.0, light=1.0,
            nutrients_regen=p["grass_nutrients_regen"],
            o2_regen=p["grass_o2_regen"],
            o2_cap=p["grass_o2_cap"],
            nutrients_cap=1.0))
    for _ in range(2):  # 2x EARTH
        chunks.append(Chunk("EARTH",
            nutrients=0.35, o2=0.21, toxins=0.0, light=0.9,
            nutrients_regen=p["earth_nutrients_regen"],
            o2_regen=p["earth_o2_regen"],
            o2_cap=p["earth_o2_cap"],
            nutrients_cap=0.7))
    # 1x WOOD
    chunks.append(Chunk("WOOD",
        nutrients=0.85, o2=0.27, toxins=0.0, light=0.25,
        nutrients_regen=p["wood_nutrients_regen"],
        o2_regen=p["wood_o2_regen"],
        o2_cap=p["wood_o2_cap"],
        nutrients_cap=1.0))
    return chunks


# ── Agent dataclasses ─────────────────────────────────────────────────────────

class Bacterium:
    __slots__ = ("energy", "age", "chunk_idx")
    def __init__(self, energy: float, chunk_idx: int):
        self.energy = energy
        self.age = 0
        self.chunk_idx = chunk_idx


class Protozoan:
    __slots__ = ("energy", "age", "hunt_timer", "chunk_idx")
    def __init__(self, chunk_idx: int):
        self.energy = 3.0
        self.age = 0
        self.hunt_timer = 0
        self.chunk_idx = chunk_idx


class Plant:
    __slots__ = ("energy", "age", "chunk_idx", "spread_timer")
    def __init__(self, chunk_idx: int):
        self.energy = 1.0
        self.age = 0
        self.chunk_idx = chunk_idx
        self.spread_timer = random.randint(100, 300)


class Fungus:
    __slots__ = ("energy", "age", "chunk_idx")
    def __init__(self, chunk_idx: int):
        self.energy = 0.8
        self.age = 0
        self.chunk_idx = chunk_idx


# ── Death cause tracking ──────────────────────────────────────────────────────

class DeathLog:
    def __init__(self):
        self.starvation = 0
        self.toxin = 0
        self.age = 0
        self.predation = 0

    def total(self) -> int:
        return self.starvation + self.toxin + self.age + self.predation

    def pct(self, n: int) -> str:
        t = self.total()
        return f"{round(n / t * 100) if t > 0 else 0}%"


# ── Simulation state ──────────────────────────────────────────────────────────

class SimState:
    def __init__(self, p: dict):
        self.p = p
        self.chunks = make_chunks(p)
        n_chunks = len(self.chunks)
        self.bacteria: list[Bacterium] = [Bacterium(1.0, i % n_chunks) for i in range(50)]
        self.protozoa: list[Protozoan] = [Protozoan(i % n_chunks) for i in range(4)]
        self.plants: list[Plant] = [Plant(i % n_chunks) for i in range(15)]
        self.fungi: list[Fungus] = [Fungus(i % n_chunks) for i in range(5)]
        self.deaths = DeathLog()
        self.births = 0
        self.tick = 0
        self.bact_peak = 50
        # Diagnostic counters (reset between milestones)
        self.ticks_overpop = 0
        self.ticks_o2_crisis = 0
        self.ticks_nutrient_dep = 0
        self.bact_history: list[int] = []

    def n_bacteria(self) -> int:
        return len(self.bacteria)

    def n_protozoa(self) -> int:
        return len(self.protozoa)

    def n_plants(self) -> int:
        return len(self.plants)

    def n_fungi(self) -> int:
        return len(self.fungi)

    def total_agents(self) -> int:
        return len(self.bacteria) + len(self.protozoa) + len(self.plants) + len(self.fungi)

    def plant_cap(self) -> int:
        return int(SOFT_CAP * self.p["plant_softcap_frac"])

    def bact_cap(self) -> int:
        return int(SOFT_CAP * self.p["bact_softcap_frac"])


# ── Tick logic ────────────────────────────────────────────────────────────────

def tick_environment(state: SimState) -> None:
    p = state.p
    chunks = state.chunks
    for c in chunks:
        c.nutrients = min(c.nutrients + c.nutrients_regen, c.nutrients_cap)
        c.o2 = min(c.o2 + c.o2_regen, c.o2_cap)
        if c.o2 < 0.19:
            c.o2 = min(c.o2 + 0.005 / 30, 0.21)
        c.toxins = max(c.toxins - p["toxin_decay"], 0.0)

    # Diffusion between neighboring chunks
    rate = p["diffuse_rate"]
    for i in range(len(chunks)):
        for j in range(i + 1, len(chunks)):
            ci, cj = chunks[i], chunks[j]
            dn = (ci.nutrients - cj.nutrients) * rate
            ci.nutrients = max(ci.nutrients - dn, 0.0)
            cj.nutrients = max(cj.nutrients + dn, 0.0)
            do2 = (ci.o2 - cj.o2) * rate
            ci.o2 = max(ci.o2 - do2, 0.0)
            cj.o2 = max(cj.o2 + do2, 0.0)


def tick_bacteria(state: SimState) -> None:
    p = state.p
    chunks = state.chunks
    dead = []
    new_bacteria = []
    bact_cap = state.bact_cap()

    for bact in state.bacteria:
        bact.age += 1
        c = chunks[bact.chunk_idx]

        if bact.age > p["bact_max_age"]:
            dead.append(bact)
            state.deaths.age += 1
            c.nutrients = min(c.nutrients + bact.energy * 0.5, c.nutrients_cap)
            continue

        bact.energy -= p["bact_metabolism"]
        if bact.energy <= 0:
            dead.append(bact)
            state.deaths.starvation += 1
            continue

        if c.toxins > p["bact_toxin_death_base"]:
            chance = (c.toxins - p["bact_toxin_death_base"]) * p["bact_toxin_death_chance"]
            if random.random() < chance:
                dead.append(bact)
                state.deaths.toxin += 1
                continue

        if c.o2 < p["bact_o2_death_thresh"]:
            chance = (p["bact_o2_death_thresh"] - c.o2) * p["bact_o2_death_chance"]
            if random.random() < chance:
                dead.append(bact)
                state.deaths.starvation += 1
                continue

        uptake = min(p["bact_uptake"], c.nutrients)
        c.nutrients -= uptake
        c.o2 = max(c.o2 - min(uptake * p["bact_o2_used_ratio"], c.o2), 0.0)
        c.toxins = min(c.toxins + uptake * p["bact_toxin_prod_ratio"], 1.0)
        bact.energy = min(bact.energy + uptake * p["bact_energy_gain_mult"], 2.0)

        if (bact.energy >= p["bact_division_threshold"]
                and state.n_bacteria() + len(new_bacteria) < bact_cap
                and state.total_agents() < SOFT_CAP):
            cost = p["bact_division_threshold"] * 0.6
            bact.energy -= cost * 0.5
            child = Bacterium(cost * 0.5, bact.chunk_idx)
            new_bacteria.append(child)
            state.births += 1

    for b in dead:
        state.bacteria.remove(b)
    state.bacteria.extend(new_bacteria)


def tick_protozoa(state: SimState) -> None:
    p = state.p
    dead = []
    new_protozoa = []
    n_bacteria = state.n_bacteria()

    for proto in state.protozoa:
        proto.age += 1
        if proto.age > p["proto_max_age"]:
            dead.append(proto)
            state.deaths.age += 1
            continue

        proto.energy -= p["proto_metabolism"]
        if proto.energy <= 0:
            dead.append(proto)
            state.deaths.starvation += 1
            continue

        proto.hunt_timer += 1
        if proto.hunt_timer >= p["proto_prey_kill_period"] and n_bacteria > 5:
            proto.hunt_timer = 0
            if state.bacteria:
                prey = random.choice(state.bacteria)
                proto.energy = min(proto.energy + prey.energy * p["proto_energy_gain"], 4.0)
                state.bacteria.remove(prey)
                state.deaths.predation += 1
                n_bacteria -= 1

        if proto.energy >= p["proto_division_energy"] and state.total_agents() < SOFT_CAP:
            proto.energy -= 0.6
            child = Protozoan(proto.chunk_idx)
            child.energy = 0.5
            new_protozoa.append(child)
            state.births += 1

    for p_ in dead:
        state.protozoa.remove(p_)
    state.protozoa.extend(new_protozoa)


def tick_plants(state: SimState) -> None:
    p = state.p
    chunks = state.chunks
    dead = []
    new_plants = []
    plant_cap = state.plant_cap()

    for plant in state.plants:
        plant.age += 1
        c = chunks[plant.chunk_idx]
        if plant.age > p["plant_max_age"]:
            dead.append(plant)
            state.deaths.age += 1
            continue

        if c.light > p["plant_light_thresh"]:
            produced = c.light * p["plant_phot_rate"]
            plant.energy = min(plant.energy + produced * 0.5, 3.0)
            c.nutrients = min(c.nutrients + produced * p["plant_nutrient_frac"], c.nutrients_cap)
            c.o2 = min(c.o2 + produced * p["plant_o2_frac"], c.o2_cap)
            c.toxins = max(c.toxins - produced * p["plant_toxin_frac"], 0.0)
        else:
            plant.energy -= p["plant_metabolism"]
            if plant.energy <= 0:
                dead.append(plant)
                state.deaths.starvation += 1
                continue

        # Spread — per-tick probability to match run_timer 100-300 avg ~200
        plant.spread_timer -= 1
        if (plant.spread_timer <= 0
                and plant.energy >= p["plant_div_energy_thresh"]
                and state.n_plants() + len(new_plants) < plant_cap
                and state.total_agents() < SOFT_CAP):
            plant.spread_timer = random.randint(100, 300)
            plant.energy -= 0.8
            child = Plant(plant.chunk_idx)
            new_plants.append(child)
            state.births += 1

    for pl in dead:
        state.plants.remove(pl)
    state.plants.extend(new_plants)


def tick_fungi(state: SimState) -> None:
    p = state.p
    chunks = state.chunks
    dead = []
    new_fungi = []

    for fungus in state.fungi:
        fungus.age += 1
        c = chunks[fungus.chunk_idx]
        if fungus.age > p["fungi_max_age"]:
            dead.append(fungus)
            state.deaths.age += 1
            continue

        fungus.energy -= p["fungi_metabolism"]
        if fungus.energy <= 0:
            dead.append(fungus)
            state.deaths.starvation += 1
            continue

        if c.nutrients < p["fungi_uptake_cond"]:
            uptake = min(p["fungi_nutrient_uptake"], c.nutrients)
            c.nutrients -= uptake
            fungus.energy = min(fungus.energy + uptake * 1.5, 2.7)

        if (fungus.energy >= 1.8
                and c.nutrients > 0.4
                and state.total_agents() < SOFT_CAP):
            fungus.energy -= 0.9
            child = Fungus(fungus.chunk_idx)
            child.energy = 0.4
            new_fungi.append(child)
            state.births += 1

    for f in dead:
        state.fungi.remove(f)
    state.fungi.extend(new_fungi)


def run_tick(state: SimState) -> None:
    state.tick += 1
    tick_environment(state)
    tick_bacteria(state)
    tick_protozoa(state)
    tick_plants(state)
    tick_fungi(state)

    nb = state.n_bacteria()
    state.bact_peak = max(state.bact_peak, nb)
    state.bact_history.append(nb)

    if nb > SOFT_CAP * 0.8:
        state.ticks_overpop += 1
    else:
        state.ticks_overpop = 0

    o2_avg = sum(c.o2 for c in state.chunks) / len(state.chunks)
    if o2_avg < 0.05:
        state.ticks_o2_crisis += 1
    else:
        state.ticks_o2_crisis = 0

    n_avg = sum(c.nutrients for c in state.chunks) / len(state.chunks)
    if n_avg < 0.02:
        state.ticks_nutrient_dep += 1
    else:
        state.ticks_nutrient_dep = 0


# ── Stats & display ───────────────────────────────────────────────────────────

def compute_o2_stats(chunks: list) -> tuple:
    vals = [c.o2 for c in chunks]
    return sum(vals) / len(vals), min(vals), max(vals)


def compute_nutrient_stats(chunks: list) -> tuple:
    vals = [c.nutrients for c in chunks]
    return sum(vals) / len(vals), min(vals), max(vals)


def determine_status(state: SimState) -> str:
    nb = state.n_bacteria()
    if nb < 10:
        return "COLLAPSED"
    hist = state.bact_history[-2000:]
    if len(hist) >= 100:
        mn, mx = min(hist), max(hist)
        if 200 <= mn and mx <= 2000:
            return "OK"
    if state.ticks_overpop > 500 or state.ticks_o2_crisis > 200 or state.ticks_nutrient_dep > 300:
        return "UNSTABLE"
    return "OK" if nb >= 10 else "COLLAPSED"


def print_stats(state: SimState, milestone: int) -> None:
    nb = state.n_bacteria()
    np_ = state.n_protozoa()
    npl = state.n_plants()
    nf = state.n_fungi()
    o2_avg, o2_min, o2_max = compute_o2_stats(state.chunks)
    n_avg, n_min, n_max = compute_nutrient_stats(state.chunks)
    tox_avg = sum(c.toxins for c in state.chunks) / len(state.chunks)
    d = state.deaths
    total_d = d.total()
    net = state.births - total_d
    status = determine_status(state)

    print(f"\n=== TICK {milestone} ===")
    print(f"Bacteria:  {nb:<6} (peak: {state.bact_peak})")
    print(f"Protozoa:  {np_}")
    print(f"Plants:    {npl}")
    print(f"Fungi:     {nf}")
    print(f"O2 avg:    {o2_avg:.3f}  (min: {o2_min:.3f}, max: {o2_max:.3f})")
    print(f"Nutrients: {n_avg:.3f}  (min: {n_min:.3f}, max: {n_max:.3f})")
    print(f"Toxins:    {tox_avg:.3f}")
    s_pct = d.pct(d.starvation)
    t_pct = d.pct(d.toxin)
    a_pct = d.pct(d.age)
    p_pct = d.pct(d.predation)
    print(f"Deaths:    {total_d} total  (starvation: {s_pct}, toxin: {t_pct}, age: {a_pct}, predation: {p_pct})")
    print(f"Births:    {state.births}")
    print(f"Net:       {'+' if net >= 0 else ''}{net}")
    print(f"Status:    {status}")


# ── Diagnostics ───────────────────────────────────────────────────────────────

class Diagnostics(NamedTuple):
    overpop: bool
    collapsed: bool
    o2_crisis: bool
    nutrient_dep: bool
    proto_extinct: bool
    proto_overpred: bool   # protozoa eating bacteria faster than they recover
    plant_monopoly: bool   # plants saturating SOFT_CAP
    oscillation_ok: bool


def run_diagnostics(state: SimState) -> Diagnostics:
    nb = state.n_bacteria()
    np_ = state.n_protozoa()
    hist = state.bact_history

    collapsed = nb < 10
    overpop = state.ticks_overpop > 500
    o2_crisis = state.ticks_o2_crisis > 200
    nutrient_dep = state.ticks_nutrient_dep > 300
    proto_extinct = (np_ == 0 and state.tick < 3000)

    # Protozoa overpredation: protozoa count high but bacteria collapsed
    proto_overpred = (np_ > 20 and nb < 50 and state.tick > 200)

    # Plant monopoly: plants taking up bulk of soft cap while bacteria collapse
    plant_monopoly = (state.n_plants() > SOFT_CAP * 0.15 and nb < 100 and state.tick > 500)

    oscillation_ok = False
    if len(hist) >= 200 and not collapsed:
        recent = hist[-2000:]
        mn, mx = min(recent), max(recent)
        if 200 <= mn and mx <= 2000:
            oscillation_ok = True

    return Diagnostics(
        overpop=overpop,
        collapsed=collapsed,
        o2_crisis=o2_crisis,
        nutrient_dep=nutrient_dep,
        proto_extinct=proto_extinct,
        proto_overpred=proto_overpred,
        plant_monopoly=plant_monopoly,
        oscillation_ok=oscillation_ok,
    )


def print_diagnostics(diag: Diagnostics, state: SimState) -> None:
    print("\n--- Diagnostics ---")
    flags = []
    if diag.oscillation_ok and not any([
        diag.overpop, diag.collapsed, diag.o2_crisis,
        diag.nutrient_dep, diag.proto_extinct, diag.proto_overpred, diag.plant_monopoly
    ]):
        flags.append("[OK] Oscillation saine detectee")
    if diag.overpop:
        flags.append("[FLAG] SURPOPULATION: bacteria > SOFT_CAP*0.8 pendant >500 ticks")
    if diag.collapsed:
        flags.append(f"[FLAG] COLLAPSED: bacteria={state.n_bacteria()}")
    if diag.o2_crisis:
        flags.append("[FLAG] O2 CRISIS: o2_avg < 0.05 pendant >200 ticks")
    if diag.nutrient_dep:
        flags.append("[FLAG] NUTRIENT DEPLETION: nutrients < 0.02 pendant >300 ticks")
    if diag.proto_extinct:
        flags.append("[FLAG] PROTOZOA EXTINCTION avant tick 3000")
    if diag.proto_overpred:
        flags.append(f"[FLAG] PROTOZOA OVERPREDATION: {state.n_protozoa()} protozoa, seulement {state.n_bacteria()} bacteria")
    if diag.plant_monopoly:
        flags.append(f"[FLAG] PLANT MONOPOLY: {state.n_plants()} plants saturent SOFT_CAP, bacteria étranglées")
    for f in flags:
        print(f"  {f}")
    if not flags:
        print("  Aucun problème détecté.")


# ── Auto-fix ──────────────────────────────────────────────────────────────────

def apply_fixes(p: dict, diag: Diagnostics, state: SimState) -> tuple[dict, list[str]]:
    new_p = dict(p)
    applied = []

    if diag.oscillation_ok and not any([
        diag.overpop, diag.collapsed, diag.o2_crisis,
        diag.nutrient_dep, diag.proto_extinct, diag.proto_overpred, diag.plant_monopoly
    ]):
        return new_p, ["Aucun fix nécessaire — oscillation saine."]

    if diag.overpop:
        new_p["bact_toxin_death_chance"] *= 1.3
        new_p["bact_division_threshold"] *= 0.9
        applied.append(f"  overpop → toxin_death_chance={new_p['bact_toxin_death_chance']:.4f}, "
                        f"division_threshold={new_p['bact_division_threshold']:.4f}")

    if diag.proto_overpred:
        # Reduce protozoa reproduction rate + increase kill period (less frequent predation)
        new_p["proto_metabolism"] *= 1.5       # harder to maintain large protozoa pop
        new_p["proto_prey_kill_period"] = int(new_p["proto_prey_kill_period"] * 1.5)
        new_p["proto_division_energy"] *= 1.3  # harder to divide
        applied.append(f"  proto_overpred → proto_metabolism x1.5={new_p['proto_metabolism']:.5f}, "
                        f"prey_kill_period={new_p['proto_prey_kill_period']}, "
                        f"division_energy={new_p['proto_division_energy']:.3f}")

    if diag.plant_monopoly:
        # Reduce plant cap fraction (enforce harder per-type limit)
        new_p["plant_softcap_frac"] = max(new_p["plant_softcap_frac"] * 0.6, 0.05)
        new_p["plant_div_period"] = int(new_p["plant_div_period"] * 1.5)
        applied.append(f"  plant_monopoly → plant_softcap_frac={new_p['plant_softcap_frac']:.3f}, "
                        f"div_period={new_p['plant_div_period']}")

    if diag.collapsed and not diag.proto_overpred and not diag.plant_monopoly:
        # Only reduce metabolism if collapse isn't caused by predation/monopoly
        new_p["bact_metabolism"] *= 0.8
        new_p["bact_uptake"] *= 1.15
        applied.append(f"  collapsed → metabolism={new_p['bact_metabolism']:.5f}, "
                        f"uptake={new_p['bact_uptake']:.5f}")

    if diag.o2_crisis:
        new_p["grass_o2_regen"] *= 1.25
        new_p["wood_o2_regen"] *= 1.25
        applied.append(f"  o2_crisis → grass_o2_regen x1.25, wood_o2_regen x1.25")

    if diag.nutrient_dep:
        new_p["bact_uptake"] = min(new_p["bact_uptake"] * 0.85, 0.018)
        new_p["grass_nutrients_regen"] *= 1.20
        new_p["earth_nutrients_regen"] *= 1.20
        new_p["wood_nutrients_regen"] *= 1.20
        applied.append(f"  nutrient_dep → uptake={new_p['bact_uptake']:.5f}, regen x1.20")

    if diag.proto_extinct and not diag.proto_overpred:
        new_p["proto_metabolism"] *= 0.7
        new_p["proto_prey_kill_period"] = max(10, int(new_p["proto_prey_kill_period"] * 0.7))
        applied.append(f"  proto_extinct → proto_metabolism={new_p['proto_metabolism']:.5f}, "
                        f"prey_kill_period={new_p['proto_prey_kill_period']}")

    return new_p, applied


# ── GDScript patch ────────────────────────────────────────────────────────────

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def patch_gdscript(p: dict, orig_p: dict) -> list[str]:
    """Write changed numeric constants back to GDScript files."""
    changes = []

    # Each entry: (file, pattern, new_value_str)
    # Values stored per-30-tick in GDScript, per-tick in sim
    patch_targets = []

    if abs(p["bact_metabolism"] - orig_p["bact_metabolism"]) > 1e-9:
        patch_targets.append((
            "scripts/managers/AgentPool.gd",
            r'(genome\.get\("metabolism",\s*)[\d.]+',
            f'\\g<1>{p["bact_metabolism"]:.5f}',
            f'bact_metabolism={p["bact_metabolism"]:.5f}'
        ))

    if abs(p["bact_uptake"] - orig_p["bact_uptake"]) > 1e-9:
        patch_targets.append((
            "scripts/managers/AgentPool.gd",
            r'(var uptake: float = minf\()[\d.]+',
            f'\\g<1>{p["bact_uptake"]:.5f}',
            f'bact_uptake={p["bact_uptake"]:.5f}'
        ))

    if abs(p["bact_toxin_death_chance"] - orig_p["bact_toxin_death_chance"]) > 1e-9:
        patch_targets.append((
            "scripts/managers/AgentPool.gd",
            r'(\(toxins - 0\.4\) \* )[\d.]+',
            f'\\g<1>{p["bact_toxin_death_chance"]:.4f}',
            f'bact_toxin_death_chance={p["bact_toxin_death_chance"]:.4f}'
        ))

    if abs(p["bact_division_threshold"] - orig_p["bact_division_threshold"]) > 1e-9:
        patch_targets.append((
            "scripts/managers/AgentPool.gd",
            r'(genome\.get\("division_threshold",\s*)[\d.]+',
            f'\\g<1>{p["bact_division_threshold"]:.4f}',
            f'bact_division_threshold={p["bact_division_threshold"]:.4f}'
        ))

    if abs(p["grass_o2_regen"] - orig_p["grass_o2_regen"]) > 1e-9:
        gd_val = p["grass_o2_regen"] * 30
        patch_targets.append((
            "scripts/autoloads/WorldGrid.gd",
            r'(2:\s*\{\s*"nutrients":[^,]+,\s*"water":[^,]+,\s*"oxygen":\s*)[\d.]+',
            f'\\g<1>{gd_val:.4f}',
            f'grass_o2_regen(gd)={gd_val:.4f}'
        ))

    if abs(p["wood_o2_regen"] - orig_p["wood_o2_regen"]) > 1e-9:
        gd_val = p["wood_o2_regen"] * 30
        patch_targets.append((
            "scripts/autoloads/WorldGrid.gd",
            r'(3:\s*\{\s*"nutrients":[^,]+,\s*"water":[^,]+,\s*"oxygen":\s*)[\d.]+',
            f'\\g<1>{gd_val:.4f}',
            f'wood_o2_regen(gd)={gd_val:.4f}'
        ))

    if abs(p["grass_nutrients_regen"] - orig_p["grass_nutrients_regen"]) > 1e-9:
        gd_val = p["grass_nutrients_regen"] * 30
        patch_targets.append((
            "scripts/autoloads/WorldGrid.gd",
            r'(2:\s*\{\s*"nutrients":\s*)[\d.]+',
            f'\\g<1>{gd_val:.4f}',
            f'grass_nutrients_regen(gd)={gd_val:.4f}'
        ))

    if abs(p["earth_nutrients_regen"] - orig_p["earth_nutrients_regen"]) > 1e-9:
        gd_val = p["earth_nutrients_regen"] * 30
        patch_targets.append((
            "scripts/autoloads/WorldGrid.gd",
            r'(1:\s*\{\s*"nutrients":\s*)[\d.]+',
            f'\\g<1>{gd_val:.4f}',
            f'earth_nutrients_regen(gd)={gd_val:.4f}'
        ))

    if abs(p["wood_nutrients_regen"] - orig_p["wood_nutrients_regen"]) > 1e-9:
        gd_val = p["wood_nutrients_regen"] * 30
        patch_targets.append((
            "scripts/autoloads/WorldGrid.gd",
            r'(3:\s*\{\s*"nutrients":\s*)[\d.]+',
            f'\\g<1>{gd_val:.4f}',
            f'wood_nutrients_regen(gd)={gd_val:.4f}'
        ))

    # Group by file
    file_contents: dict[str, str] = {}
    for fname, pattern, replacement, label in patch_targets:
        fpath = os.path.join(BASE_DIR, fname)
        if fname not in file_contents:
            if not os.path.exists(fpath):
                changes.append(f"  SKIP (not found): {fname}")
                continue
            with open(fpath, "r") as f:
                file_contents[fname] = f.read()
        original = file_contents[fname]
        new_content = re.sub(pattern, replacement, original, flags=re.DOTALL)
        if new_content != original:
            file_contents[fname] = new_content
            changes.append(f"  PATCHED {fname}: {label}")
        else:
            changes.append(f"  NO MATCH {fname}: {label} (pattern: {pattern[:50]})")

    for fname, content in file_contents.items():
        fpath = os.path.join(BASE_DIR, fname)
        with open(fpath, "w") as f:
            f.write(content)

    return changes if changes else ["  Aucun patch GDScript appliqué (valeurs inchangées)."]


# ── Main simulation loop ──────────────────────────────────────────────────────

def run_simulation(p: dict, label: str = "") -> SimState:
    state = SimState(p)
    milestones = [500, 2000, 5000, 10000]
    m_idx = 0
    print(f"\n{'='*50}")
    if label:
        print(f"  Simulation: {label}")
    print(f"{'='*50}")

    for _ in range(10000):
        run_tick(state)
        if m_idx < len(milestones) and state.tick == milestones[m_idx]:
            print_stats(state, milestones[m_idx])
            m_idx += 1
        if state.tick > 2000 and state.n_bacteria() == 0 and state.n_protozoa() == 0:
            print(f"\n[!] Effondrement total au tick {state.tick}. Arrêt anticipé.")
            break

    return state


def main() -> None:
    p = copy.deepcopy(PARAMS)
    orig_p = copy.deepcopy(PARAMS)

    print("\n" + "="*60)
    print("  ECO_SIM — Primordia Ecological Simulation Tool")
    print("="*60)
    print(f"  Monde: 4xGRASS + 2xEARTH + 1xWOOD | SOFT_CAP={SOFT_CAP}")
    print(f"  Start: 50 bacteria, 4 protozoa, 15 plants, 5 fungi")

    max_iterations = 3
    stable = False

    for iteration in range(max_iterations):
        print(f"\n\n{'#'*60}")
        print(f"  ITERATION {iteration + 1}/{max_iterations}")
        print(f"{'#'*60}")

        state = run_simulation(p, label=f"Run #{iteration + 1}")

        print(f"\n\n--- Diagnostics finaux (tick {state.tick}) ---")
        diag = run_diagnostics(state)
        print_diagnostics(diag, state)

        is_stable = diag.oscillation_ok and not any([
            diag.overpop, diag.collapsed, diag.o2_crisis,
            diag.nutrient_dep, diag.proto_extinct, diag.proto_overpred, diag.plant_monopoly
        ])
        if is_stable:
            print("\n[OK] Simulation STABLE.")
            stable = True
            break

        new_p, applied_fixes = apply_fixes(p, diag, state)

        if new_p == p:
            print("\n[!] Aucun fix applicable supplémentaire.")
            break

        print("\n--- Fixes appliqués ---")
        for fix in applied_fixes:
            print(fix)

        if iteration == max_iterations - 1 or new_p != p:
            print("\n--- Patch GDScript ---")
            gdscript_changes = patch_gdscript(new_p, orig_p)
            for ch in gdscript_changes:
                print(ch)

        p = new_p

    # Final parameter summary
    print("\n\n" + "="*60)
    print(f"  PARAMETRES FINAUX {'(STABLE)' if stable else '(meilleure approximation)'}")
    print("="*60)
    changed_any = False
    for key in sorted(orig_p.keys()):
        ov = orig_p[key]
        nv = p[key]
        if isinstance(ov, float):
            changed = abs(ov - nv) > 1e-9
        else:
            changed = ov != nv
        if changed:
            changed_any = True
            print(f"  {key:<35} {ov:.6g} -> {nv:.6g}  <-- MODIFIE")
    if not changed_any:
        print("  Aucun paramètre modifié (simulation stable dès le premier run).")


if __name__ == "__main__":
    main()
