# TODO.md — Primordia
> Mise à jour : 2026-05-08 | Légende : [ ] todo · [x] done · [~] en cours · [!] bloqué

---

## Phase 0 — Recherche scientifique (OBLIGATOIRE avant tout code de simulation)

> Chaque agent de recherche produit un fichier `research/YYYY-MM-DD_HH-MM_<sujet>.md`
> Format obligatoire : titre · timestamp · sujet · état (draft/final) · sources · synthèse actionnable

- [ ] Agent 01 — Microbiologie bactérienne : cycles de vie, chimiotaxie, sporulation, résistance, gram+/-
- [ ] Agent 02 — Virologie : réplication, souches ARN/ADN, mutation, R0, immunité mémoire
- [ ] Agent 03 — Épidémiologie : modèles SIR/SEIR, taux de propagation, herd immunity, vecteurs
- [ ] Agent 04 — Chaîne alimentaire & écologie : niveaux trophiques, Lotka-Volterra, extinction, équilibre
- [ ] Agent 05 — IA collective : Boids, stigmergie, phéromones, meutes, colonies, comportements émergents
- [ ] Agent 06 — Génétique & évolution : mutation, sélection naturelle, dérive génétique, spéciation
- [ ] Agent 07 — Anatomie fonctionnelle : systèmes sanguin/musculaire/nerveux, fatigue, blessures
- [ ] Agent 08 — Physique de simulation : diffusion, gradient chimique, thermodynamique cellulaire
- [ ] Agent 09 — Parasitisme & symbiose : types de relations inter-espèces, co-évolution
- [ ] Agent 10 — Références jeux existants : Spore, Plague Inc, Species ALRE, Dwarf Fortress bio-layer

---

## Phase 1 — Core Engine

- [ ] Initialiser le projet Godot 4 (`project.godot`, structure dossiers)
- [ ] Autoload `SimulationClock` : tick loop indépendant du rendu, pause, set_speed (0.1x – 32x)
- [ ] Grille monde `WorldGrid` : cellules discrètes avec nutriments, eau, température, oxygène, pH, toxines
- [ ] Système de coordonnées : world pos ↔ grid cell ↔ screen pos
- [ ] Scène principale `World.tscn` + Camera2D multi-échelle
- [ ] Zoom 3 niveaux : macro (écosystème), meso (individus), micro (cellulaire/bactérien)
- [ ] Affichage conditionnel selon zoom : bactéries visibles seulement en micro, espèces en meso+
- [ ] `TimeControlBar` UI : pause / play / vitesse / step-by-step
- [ ] Debug overlay : FPS, tick rate, population totale, grille visible

---

## Phase 2 — Bactéries & Virus

### Bactéries
- [ ] Classe `Bacterium` : génome minimal (vitesse, métabolisme, résistance, virulence)
- [ ] Déplacement brownien + chimiotaxie (attraction vers nutriments)
- [ ] Consommation nutriments de la cellule occupée
- [ ] Reproduction asexuée (division binaire) avec délai métabolique
- [ ] Mort par manque d'énergie / âge / attaque immunitaire
- [ ] Décomposition : restitue nutriments à la grille
- [ ] Sporulation : état dormant en conditions hostiles (température extrême, sécheresse)
- [ ] Résistance évolutive : mutation ±X% à chaque génération
- [ ] Types bactériens : gram+, gram-, anaérobie, aérobie, extrémophile

### Virus
- [ ] Classe `Virus` : particule non-vivante, pas d'énergie propre
- [ ] Propagation par contact direct (distance < seuil)
- [ ] Propagation aérienne : rayon + probabilité + durée de vie dans l'air
- [ ] Infection : tentative d'entrée dans l'hôte (résistance vs virulence)
- [ ] Réplication intracellulaire : incubation → multiplication → lyse ou latence
- [ ] Mutation virale à chaque réplication (dérive génétique)
- [ ] Souches : ARN (grippe-like), ADN (herpes-like), rétrovirus-like
- [ ] Immunité hôte : mémoire immunitaire post-infection
- [ ] Taux létalité configurable par souche

### Contamination
- [ ] Système de propagation avec carte de densité infectieuse
- [ ] Vecteurs de contamination : contact, air, eau, sol, autre espèce
- [ ] Visualisation overlay de la zone de contamination active
- [ ] Résistance collective : effet "herd immunity" simulé
- [ ] Épidémie log : R0 calculé en temps réel, courbe de propagation

---

## Phase 3 — Macro Organismes & Chaîne Alimentaire

### Stats par spécimen
- [ ] Dangerosité (0-100) : capacité d'attaque + toxicité
- [ ] Force : dégâts infligés, résistance aux impacts
- [ ] Rapidité : vitesse de déplacement + réaction
- [ ] Endurance : réserve d'énergie avant épuisement
- [ ] Métabolisme : consommation d'énergie au repos et en effort
- [ ] Résistance : défense physique + immunité aux maladies
- [ ] Acuité sensorielle : portée de détection proies/prédateurs/ressources
- [ ] Fertilité : fréquence et quantité de reproduction
- [ ] Âge max / maturité sexuelle / gestation
- [ ] Température corporelle, besoins hydriques, besoins nutritifs

### Anatomie simulée (interne)
- [ ] Système sanguin : transport oxygène/nutriments, hémorragie possible
- [ ] Muscles : fatigue musculaire, récupération, impact sur la force/vitesse
- [ ] Organes vitaux : cœur, poumons, foie — dégradation sous maladie ou blessure
- [ ] État de santé global : composite des systèmes internes

### Espèces
- [ ] Microbiote (bactéries + virus — Phase 2)
- [ ] Protozoaires : prédateurs de bactéries, unicellulaires
- [ ] Champignons : décomposeurs, parasites possibles
- [ ] Plantes / algues : producteurs primaires, fixent nutriments
- [ ] Herbivores : consomment plantes
- [ ] Carnivores : consomment herbivores et plus faibles
- [ ] Omnivores : opportunistes
- [ ] Parasites : vivent sur/dans un hôte, l'affaiblissent
- [ ] Décomposeurs : recyclent cadavres en nutriments

### Chaîne alimentaire
- [ ] Graphe trophique : qui mange quoi
- [ ] Transfert d'énergie : 10% règle (pertes à chaque niveau)
- [ ] Compétition intra-espèce pour ressources
- [ ] Équilibre proie/prédateur (dynamique Lotka-Volterra)
- [ ] Extinction : espèce sous seuil critique → disparition + log

### IA Individuelle
- [ ] FSM `AgentBrain` : idle → chercher nourriture → fuir → chasser → reproduire → mourir
- [ ] Pathfinding sur grille (A* simplifié)
- [ ] Mémoire courte : position dernière ressource connue
- [ ] Instinct : fuite automatique si prédateur détecté dans rayon sensoriel

### IA Collective
- [ ] `SwarmDirector` : gestion de groupes (meutes, bancs, essaims, colonies)
- [ ] Comportements émergents : flocking (Boids), formations, embuscades
- [ ] Meute de loups : chasse coordonnée, rôles (traqueurs, chasseurs, sentinelles)
- [ ] Colonie de fourmis/abeilles : division du travail, phéromones simulées
- [ ] Migration saisonnière si biomes avec saisons activées

### Évolution
- [ ] Mutation génétique à chaque génération (stats ±X%)
- [ ] Sélection naturelle : les mieux adaptés survivent et se reproduisent plus
- [ ] Spéciation sur longue durée (si divergence stats > seuil)
- [ ] Arbre généalogique par lignée (optionnel, intensif en mémoire)

---

## Phase 4 — Visuels & Shaders

- [ ] Shader cartoon : outline noir, aplats couleur, palette unique par espèce
- [ ] Génération procédurale des sprites : forme + taille + couleur selon stats

### Formes réalistes par espèce (procédural, zéro texture)

**Bactéries**
- [ ] Cocci (Staphylococcus-like) : sphère, grappes de 4-8 selon génome
- [ ] Bacille (E.coli-like) : ovale allongé, ratio longueur/largeur selon speed
- [ ] Spirille (Helicobacter-like) : courbe sinusoïdale animée
- [ ] Flagelle : ligne ondulante rotative selon vitesse de déplacement, absent en spore
- [ ] Membrane gram+ épaisse visible (double cercle) vs gram- fine (cercle simple)
- [ ] Animation division : forme en 8 → séparation progressive sur N ticks
- [ ] Spore : cercle compact avec paroi épaisse, couleur terreuse, taille réduite

**Virus**
- [ ] Icosaèdre à spicules 2D (influenza/coronavirus) : hexagone + 6-12 pointes rayonnantes
- [ ] Bactériophage : tête hexagonale + queue + 6 pattes d'injection (virus ADN)
- [ ] Filamenteux (Ebola-like) : long fil ondulant, longueur proportionnelle à virulence
- [ ] Halo de propagation semi-transparent animé (rayon = transmission_radius)
- [ ] Couronne de glycoprotéines pour les coronavirus-like (spicules arrondis)

**Malformations à la naissance**
- [ ] Flagelle absent (mutation) : bactérie immobile, coût survival +30%
- [ ] Membrane asymétrique : forme déformée générée via noise sur le rayon
- [ ] Division incomplète : cellule bicéphale (deux noyaux visibles, un seul corps)
- [ ] Probabilité malformation : 1-5% par division, augmente avec taux de mutation élevé
- [ ] Malformation létale (>seuil) : mort immédiate à la naissance
- [ ] Filtre "bactérien" : overlay bioluminescent, halos de densité, particules flottantes
- [ ] Filtre "sanguin" : vaisseaux visibles, rougeur selon blessure, éclaboussures
- [ ] Filtre "musculaire" : fibres visibles, contraction animée lors d'effort
- [ ] Filtre "neuronal" (si IA complexe) : synapses lumineuses, activité cérébrale
- [ ] Effets particules : mort, division bactérienne, contamination, combat, reproduction
- [ ] Heatmap overlay : densité / nutriments / danger / infection
- [ ] Biomes visuels : aquatique (bleu, plancton), terrestre (vert), désert (ocre), profondeur (noir)
- [ ] Cycles jour/nuit avec impact comportemental
- [ ] Transitions douces entre filtres (lerp params shader)
- [ ] Zoom micro : cellules visibles, noyaux, membrane, bactéries sur hôte

---

## Phase 5 — Stats UI & Inspector

- [ ] Panel stats globales : populations, ressources, taux contamination, R0 actif
- [ ] Graphes temps-réel : courbes de population par espèce (style Lotka-Volterra)
- [ ] Graphe chaîne alimentaire : visualisation du graphe trophique en cours
- [ ] Specimen inspector : clic → panel complet (toutes stats, état anatomique, historique de vie)
- [ ] Bactérie inspector : génome, génération, souche, taux mutation
- [ ] Virus inspector : souche, R0, taux létalité, nombre d'infectés actifs
- [ ] Leaderboard espèces : dominantes, en déclin, menacées d'extinction
- [ ] Événements log : extinctions, épidémies, pics de prédation, spéciations
- [ ] Export snapshot (JSON local) : état complet de la simulation à un instant T
- [ ] Rejouer un événement majeur (si snapshot disponible)

---

## Backlog / Idées futures

- [ ] Éditeur d'environnement : dessiner des zones, changer biome, poser ressources manuellement
- [ ] Scénarios prédéfinis : "Épidémie mortelle", "Extinction en cascade", "Équilibre parfait"
- [ ] Accélération GPU (si trop lent à grande échelle — migration MultiMesh)
- [ ] Mode "arbre de la vie" : phylogénie complète de toutes les espèces nées en session
- [ ] Son procédural : ambiance générée selon densité de population et événements
