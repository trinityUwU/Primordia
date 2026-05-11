# TODO.md — Primordia
> Mise à jour : 2026-05-11 | Légende : [ ] todo · [x] done · [~] en cours · [!] bloqué

---

## Phase 0 — Recherche scientifique ✅

- [x] Agent 01 — Microbiologie bactérienne : cycles de vie, chimiotaxie, sporulation, résistance, gram+/-
- [x] Agent 02 — Virologie : réplication, souches ARN/ADN, mutation, R0, immunité mémoire
- [x] Agent 03 — Épidémiologie : modèles SIR/SEIR, taux de propagation, herd immunity, vecteurs
- [x] Agent 04 — Chaîne alimentaire & écologie : niveaux trophiques, Lotka-Volterra, extinction, équilibre
- [x] Agent 05 — IA collective : Boids, stigmergie, phéromones, meutes, colonies, comportements émergents
- [x] Agent 06 — Génétique & évolution : mutation, sélection naturelle, dérive génétique, spéciation
- [x] Agent 07 — Anatomie fonctionnelle : systèmes sanguin/musculaire/nerveux, fatigue, blessures
- [x] Agent 08 — Physique de simulation : diffusion, gradient chimique, thermodynamique cellulaire
- [x] Agent 09 — Parasitisme & symbiose : types de relations inter-espèces, co-évolution
- [x] Agent 10 — Références jeux existants : Spore, Plague Inc, Species ALRE, Dwarf Fortress bio-layer

---

## Phase 1 — Core Engine ✅

- [x] Initialiser le projet Godot 4 (`project.godot`, structure dossiers)
- [x] Autoload `SimulationClock` : tick loop indépendant du rendu, pause, set_speed (0.1x – 32x)
- [x] Grille monde `WorldGrid` : monde infini par chunks 32×32 cellules, 7 champs chimiques
- [x] Système de coordonnées : world pos ↔ grid cell ↔ screen pos
- [x] Scène principale `World.tscn` + Camera2D multi-échelle
- [x] Zoom adaptatif au viewport (WASD + flèches + scroll + pan clic milieu)
- [x] `TimeControlBar` UI : pause / play / vitesse (0.1x→32x) / step-by-step
- [x] Debug overlay : FPS, tick rate, zoom, coords souris (F1), grille debug (G)

---

## Phase 2 — Bactéries & Virus ✅

- [x] Data-oriented `AgentPool` : PackedFloat32Array, zéro Node2D, MAX=3000, TICK_STRIDE=2
- [x] Bactéries : chimiotaxie run-and-tumble, division avec mutation génomique, sporulation, gram+/-
- [x] Virus : mouvement brownien, propagation par contact, infection, lifetime
- [x] Cadavres : 300 ticks de decay avec fade visuel
- [x] `ChunkSpawner` : spawn dans 800px autour caméra, règles écologiques (nutrients, densité)
- [x] `SimRenderer` : MultiMeshInstance2D, culling viewport, clustering 24px, tooltip hover
- [x] Shader `agent.gdshader` : 5 types visuels (gram+/-, spore, virus, dead)
- [x] Performances : ~800 agents, 60fps x1, ~40fps x16 (dirty flag + MAX_TICKS=4)

---

## Phase 2 — En cours / corrections

- [~] Vérifier FPS réels à x16/x32 après dernier fix
- [~] Tester clustering tooltip visuellement
- [x] Fixer debug overlay Population (branché à AgentPool._type_counts — OK)

---

## Phase 3b — Environnement & Biomes

### Biome system
- [x] BiomeMap : chaque chunk a un type (eau, terre, herbe, bois, roche)
- [x] Valeurs initiales par biome (nutrients, water, temperature, oxygen, ph, toxins, light)
- [x] Limites de régénération par biome (eau régénère water vite, forêt régénère nutrients)
- [x] Impact spawn : ChunkSpawner filtre par biome (anaérobies en eau, etc.)

### Rendu biomes
- [x] Flat color par biome (fond coloré selon type de chunk)
- [x] Shader texturing procédural par biome (grain, pattern, variation noise)
- [x] Transitions douces entre biomes (Voronoi jitter par chunk — seam-free, organique)
- [x] Overlay heatmap : nutrients / toxins / temperature (toggle)

### Éditeur in-game
- [x] Outil peinture : sélectionner un biome et peindre des chunks au clic
- [x] UI palette biomes (panneau latéral gauche)
- [x] Raccourci clavier pour activer/désactiver le mode éditeur

---

## Phase 3e — Génération Procédurale de Monde 🔜 PRIORITÉ 1

### WorldGen — génération à la volée par chunk
- [ ] `WorldGen` autoload : génère un chunk à partir de ses coordonnées (seed mondial déterministe)
- [ ] Noise multi-octave (FastNoiseLite Godot) : altitude, humidité, température — chaque couche indépendante
- [ ] Biome assignment depuis altitude + humidité + température :
  - altitude > 0.75 → ROCK
  - altitude < 0.25 → WATER (océan)
  - humidité > 0.7 + altitude 0.3-0.6 → WOOD
  - humidité 0.3-0.7 → GRASS
  - humidité < 0.3 → EARTH (désert/plaine)
- [ ] Initialisation cohérente des champs chimiques selon biome généré
- [ ] Continuité inter-chunks : le noise est mondial (coordonnées chunk × chunk_size = seed position)
- [ ] Remplacement du BiomeEditor comme seule source de vérité → génération automatique à la création du chunk
- [ ] Option "regenerate world" depuis le menu (nouvelle seed)

### Macro-structures procédurales
- [ ] Rivières : pathfinding descente d'altitude → trace de chunks WATER entre montagnes et océan
- [ ] Montagnes : clusters ROCK cohérents avec transition GRASS → WOOD → ROCK selon altitude
- [ ] Forêts : clusters WOOD avec densité noise, lisières naturelles
- [ ] Conditions d'habitabilité par zone : température + humidité + nutriments → score propice par espèce
  - Zones propices → spawn naturel favorisé pour espèces compatibles (fourmis en terre sèche, champignons en forêt humide, etc.)

---

## Phase 3f — Layers Écologiques 🔜 PRIORITÉ 2

### Système de layers
- [ ] 4 layers : `ATMOSPHERE`, `SURFACE`, `SOIL`, `UNDERGROUND`
- [ ] Chaque chunk stocke des champs chimiques par layer (oxygen/humidity dans ATMOSPHERE, nutrients/pH dans SOIL, etc.)
- [ ] Agents ont un `layer` dans AgentPool — tick uniquement dans leur layer actif
- [ ] Migration inter-layers : spores → ATMOSPHERE, fungi hyphes → SOIL, bactéries sol ↔ surface selon humidité
- [ ] ChunkSpawner génère par layer selon conditions
- [ ] Touche dédiée pour switcher de layer (ex: Tab) — transition visuelle fondu

### Champs par layer
- ATMOSPHERE : oxygen, co2, humidity, spore_density, temperature (aérien)
- SURFACE : nutrients, water, toxins, temperature, light (actuel)
- SOIL : nutrients, water, pH, minerals, organic_matter
- UNDERGROUND : minerals, pressure, temperature, water (nappe)

---

## Phase 3g — DA Refonte Shaders 🔜 PRIORITÉ 3

### Style Factorio-inspired : lisible, organique, informatif
- [ ] Biome shader : noise de détail par biome (grain sable, fibres herbe, écorce bois, mousse roche)
- [ ] Variations subtiles de teinte intra-biome (pas flat color)
- [ ] Transitions biomes : blend sur 2-3 cells au lieu de frontière dure
- [ ] Eau : profondeur simulée (plus sombre au centre), reflets dynamiques améliorés
- [ ] Éclairage ambiant : light venant du layer ATMOSPHERE (luminosité solaire selon heure simulée)
- [ ] Agents : formes procédurales selon type (cocci/bacille/spirille pour bactéries) — voir Phase 4
- [ ] Palette cohérente par biome — chaque biome a une identité visuelle reconnaissable instantanément

---

## Phase 3c — Architecture Écologique & Performance

### Simulation auto-entretenue
- [x] ChunkSpawner → mode seed uniquement au démarrage, population maintenue par reproduction
- [x] Équilibre division/mort : uptake 0.018, toxins progressifs 0.4→, O2 seuil rehaussé
- [x] Nutrient cycle fermé : plantes dégradent toxines, bactéries saturent zone → mort naturelle
- [~] Stabilisation O2/CO2 — buffer atmosphérique + pas de write O2 par agents
- [ ] Mode simulation réelle : spawn conditionnel (O2, nutrients, eau, température)
- [ ] Option settings "Seeded start" vs "Natural emergence" — désactiver spawn initial forcé
- [ ] Vérification équilibre : O2 stable 0.19–0.23 au repos, pics bactériens Lotka-Volterra naturels

### Scale
- [x] MAX_AGENTS dynamique (RAM-based) — calculé au démarrage, budget 4GB, ~20M max
- [x] LOD simulation : PopulationLOD — zone active individus, hors zone = counts agrégés par chunk
- [x] DensityFogRenderer : halos lumineux par chunk agrégé (1 quad/chunk, bloom shader)
- [x] Chunk data compression pour chunks inactifs

### Monde persistant
- [x] Biomes persistants via _biome_map séparé, jamais evicté
- [x] Regen sur tous les chunks (pas seulement actifs)
- [x] Chunk eviction préserve le biome_type

### Perf — GPU Compute (après stabilisation écologie)
- [ ] Diffusion WorldGrid → compute shader GLSL via RenderingDevice (gain massif, stencil uniforme)
- [ ] Mouvement agents → compute shader (intégration position)
- [ ] Spatial hash GPU pour détection voisins
- [ ] FSM complexe + division/mort restent CPU
- [ ] GDExtension C++ pour SIMD si FSM devient bottleneck
- [ ] TICK_STRIDE adaptatif selon charge CPU
- [ ] Profiling : identifier bottleneck à 100K+ agents

---

## Phase 3d — LOD Rendu Densité & Visibilité

- [x] DensityFogRenderer : halos lumineux par chunk agrégé (1 quad/chunk, bloom shader)
- [x] SimRenderer O(viewport) : spatial hash pour culling agents hors vue
- [x] Tooltip popup au hover sur zone de densité (stats du chunk agrégé : counts par type)
- [x] Zoom-LOD transition : fondu entre quads individuels et halo densité selon zoom level
- [x] Sélection d'entités individuelles à afficher par type depuis un menu (voir spec)

---

## Phase 3 — Macro Organismes & Chaîne Alimentaire

### Stats par spécimen
- [ ] Dangerosité, Force, Rapidité, Endurance, Métabolisme, Résistance, Acuité sensorielle, Fertilité
- [ ] Âge max / maturité sexuelle / gestation
- [ ] Température corporelle, besoins hydriques et nutritifs

### Anatomie simulée (interne)
- [ ] Système sanguin : transport oxygène/nutriments, hémorragie possible
- [ ] Muscles : fatigue musculaire, récupération
- [ ] Organes vitaux : cœur, poumons, foie — dégradation sous maladie ou blessure
- [ ] État de santé global : composite des systèmes internes

### Espèces
- [x] Protozoaires : prédateurs de bactéries, unicellulaires — FSM IDLE/SEEK/HUNT/REPRODUCE actif
- [ ] Champignons : décomposeurs, parasites possibles
- [ ] Plantes / algues : producteurs primaires, fixent nutriments
- [ ] Herbivores, Carnivores, Omnivores, Parasites, Décomposeurs

### Chaîne alimentaire
- [ ] Graphe trophique : qui mange quoi
- [ ] Transfert d'énergie : règle des 10%
- [ ] Compétition intra-espèce
- [ ] Équilibre proie/prédateur (Lotka-Volterra)
- [ ] Extinction : espèce sous seuil critique → disparition + log

### IA Individuelle
- [ ] FSM `AgentBrain` : idle → chercher nourriture → fuir → chasser → reproduire → mourir
- [ ] Pathfinding sur grille (A* simplifié)
- [ ] Mémoire courte : position dernière ressource connue
- [ ] Instinct de fuite si prédateur dans rayon sensoriel

### IA Collective
- [ ] `SwarmDirector` : gestion de groupes (meutes, bancs, essaims, colonies)
- [ ] Flocking (Boids), formations, embuscades
- [ ] Meute : chasse coordonnée, rôles (traqueurs, chasseurs, sentinelles)
- [ ] Colonie : division du travail, phéromones simulées
- [ ] Migration saisonnière (si biomes avec saisons)

### Évolution
- [ ] Mutation génétique à chaque génération (stats ±X%)
- [ ] Sélection naturelle : les mieux adaptés survivent plus
- [ ] Spéciation sur longue durée (divergence stats > seuil)
- [ ] Héritage ancestral : traits = moyenne des N dernières générations + mutation (voir Phase 6)

---

## Phase 4 — Visuels & Shaders

- [ ] Shader cartoon : outline noir, aplats couleur, palette unique par espèce
- [ ] Génération procédurale sprites : forme + taille + couleur selon stats

### Formes réalistes bactéries (procédural, zéro texture)
- [ ] Cocci : sphère, grappes de 4-8 selon génome
- [ ] Bacille : ovale allongé, ratio selon speed
- [ ] Spirille : courbe sinusoïdale animée
- [ ] Flagelle : ligne ondulante rotative, absent en spore
- [ ] Membrane gram+ épaisse (double cercle) vs gram- fine
- [ ] Animation division : forme en 8 → séparation progressive
- [ ] Spore : cercle compact avec paroi épaisse

### Formes réalistes virus
- [ ] Icosaèdre à spicules 2D (hexagone + 6-12 pointes)
- [ ] Bactériophage : tête + queue + 6 pattes d'injection
- [ ] Filamenteux : long fil ondulant
- [ ] Halo propagation semi-transparent animé

### Malformations à la naissance
- [ ] Flagelle absent (mutation) : bactérie immobile
- [ ] Membrane asymétrique : forme déformée via noise
- [ ] Division incomplète : cellule bicéphale
- [ ] Probabilité malformation : 1-5% par division

### Filtres visuels
- [ ] Filtre "bactérien" : bioluminescent, halos de densité, particules
- [ ] Filtre "sanguin" : vaisseaux visibles, rougeur selon blessure
- [ ] Filtre "musculaire" : fibres visibles, contraction animée
- [ ] Filtre "neuronal" : synapses lumineuses
- [ ] Heatmap overlay : densité / nutriments / danger / infection
- [ ] Biomes visuels : aquatique, terrestre, désert, profondeur
- [ ] Cycles jour/nuit avec impact comportemental
- [ ] Transitions douces entre filtres (lerp params shader)
- [ ] Zoom micro : cellules visibles, noyaux, membrane

### Environnement / Biomes
- [x] Biomes visuels : déplacé en Phase 3b

---

## Phase 5 — Stats UI & Inspector

- [ ] Panel stats globales : populations, ressources, taux contamination, R0 actif
- [ ] Graphes temps-réel : courbes de population par espèce (Lotka-Volterra style)
- [ ] Graphe chaîne alimentaire : visualisation graphe trophique en direct
- [ ] Specimen inspector : clic → panel complet (toutes stats, état anatomique, historique)
- [ ] Bactérie inspector : génome, génération, souche, taux mutation
- [ ] Virus inspector : souche, R0, taux létalité, nombre d'infectés actifs
- [ ] Leaderboard espèces : dominantes, en déclin, menacées d'extinction
- [ ] Événements log : extinctions, épidémies, pics de prédation, spéciations
- [ ] Export snapshot JSON local : état complet à un instant T

---

## Phase 6 — Biologie Profonde & Survie Réaliste

### Besoins vitaux par specimen (requirements = conditions de vie)
- [ ] Faim : réserve énergétique, mort par inanition si vide
- [ ] Soif : réserve hydrique, mort par déshydratation
- [ ] Respiration : consommation O2, mort par asphyxie (O2 < seuil)
- [ ] Thermorégulation : plage de température viable par espèce, mort par hypothermie/hyperthermie
- [ ] Pression atmosphérique : impact sur espèces aquatiques vs terrestres

### Systèmes physiologiques
- [ ] Sang : volume sanguin, hémorragie (perte % par blessure), mort si > 40% perdu
- [ ] Transpiration : perte hydrique en chaleur, nécessite réhydratation
- [ ] Immunité : résistance aux infections, mémoire immunitaire post-guérison
- [ ] Blessures : fractures, lacérations — réduction stats (vitesse, force), guérison possible
- [ ] Infection : bactéries/virus qui colonisent un hôte, dégradation progressive organes
- [ ] Fatigue musculaire : effort → accumulation de lactate → ralentissement

### Génétique & évolution réaliste
- [ ] Héritage ancestral : chaque trait = moyenne des N dernières générations + mutation
- [ ] Traits comportementaux héritables : paresse, agressivité, socialité, timidité
- [ ] Convergence évolutive : mutation rare (1/1B) peut créer un nouveau trait dominant
- [ ] Arbre généalogique : tracer les lignées, visualiser les branches
- [ ] Pression de sélection : traits favorables dans l'environnement = reproduction plus fréquente
- [ ] Dérive génétique : petites populations → traits aléatoires fixés même sans sélection

### Interactions sociales
- [ ] Besoin de contact social (mammifères, insectes sociaux) — stress si isolé
- [ ] Formation de groupes, hiérarchies, coopération
- [ ] Transmission culturelle : comportements appris transmis aux descendants

### Espèces macro (Phase 3 étendue)
- [ ] Reptiles (lézards, serpents) : ectothermes, dépendants température externe
- [ ] Insectes : arthropodes, exosquelette, métamorphose, colonies
- [ ] Mammifères simples : endothermes, gestation, allaitement, soins parentaux
- [ ] Humanoïdes (très long terme) : outils, langage, société

---

## Backlog / Idées futures

- [ ] Scénarios prédéfinis : "Épidémie mortelle", "Extinction en cascade", "Équilibre parfait"
- [ ] Mode "arbre de la vie" : phylogénie complète de toutes les espèces nées en session
- [ ] Son procédural : ambiance générée selon densité et événements
