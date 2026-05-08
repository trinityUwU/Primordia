# STATE.md — Primordia

> Résumé vivant cross-session. Max 300 lignes. Archiver si trop long.
> Dernière mise à jour : 2026-05-08

---

## Current State

Projet initialisé. Aucun code écrit. Structure de fichiers définie.

---

## Active Features

Aucune — projet en phase 0.

---

## In Progress

- Définition de l'architecture (voir Architecture Notes)
- Backlog structuré (voir TODO.md)

---

## Known Issues

Aucun.

---

## Architecture Notes

### Simulation loop
- Tick-based via `SimulationClock` (autoload) — fréquence configurable
- Séparation claire entre tick logique et frame de rendu
- `get_process_delta_time()` ignoré pour la logique sim — tout passe par le tick

### World grid
- Grille 2D de cellules — taille paramétrable (ex : 256x256)
- Chaque cellule contient : nutriments, température, humidité, liste d'agents présents
- Accès O(1) par position discrète

### Agents
- Classe de base `Agent` (Resource ou Node2D selon besoin de rendu)
- Stats par spécimen : dangerosité, vitesse, force, métabolisme, résistance, taille, âge, énergie
- Deux couches d'IA : individuelle (`AgentBrain`) + collective (`SwarmDirector`)
- Contamination : propagation par contact ou rayon selon type de pathogène

### Shaders / filtres visuels
- Filtres switchables en runtime : normal / sang / muscles / overlay bactérien
- Implémentés comme CanvasItem shaders sur un layer dédié
- Palette cartoon : outline noir, aplats, pas de texture photoréaliste

### Contrôles temps
- `SimulationClock` expose : `pause()`, `set_speed(float)` (0.25x à 8x)
- UI temps-réel via `TimeControlBar` (scène UI indépendante)

### Zoom multi-échelle
- Camera2D avec niveaux définis : macro (écosystème), meso (groupe), micro (cellulaire)
- Affichage conditionnel selon zoom : détails cachés en vue macro, labels cachés en vue micro
