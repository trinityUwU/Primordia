# Références Jeux de Simulation — Recherche Primordia
**Timestamp** : 2026-05-08
**Sujet** : Références jeux existants — analyse technique et design
**État** : final
**Sources** : Connaissance de training (Wikipedia, Steam, forums, GDC talks, articles critiques)
**Agent** : Claude Sonnet 4.6 — recherche sans accès web (WebFetch non autorisé)

---

## Synthèse actionnable pour Primordia

### Ce qu'on retient

| Pattern | Source | Application Primordia |
|---|---|---|
| Arbre de mutations visible et tactile | Plague Inc | Arbre d'évolution génomique interactif |
| Comportements émergents via réseaux de neurones | Ecosystem | Cerveaux évolutifs pour agents biologiques |
| Simulation physique cellulaire par particules | The Powder Toy | Couche chimique/physique de l'environnement |
| Génétique à allèles dominants/récessifs | Niche | Génome diploïde, phénotype visible |
| Détail anatomique complet par corps | Dwarf Fortress | Organes, maladies, blessures par tissu |
| Évolution en temps réel observable | Species ALRE | Arbre phylogénétique live |
| Progression fluide micro → macro | Spore (cell phase) | Transition de l'unicellulaire à la multicellularité |
| Open source + comunauté active | Thrive | Publication open du moteur de simulation |

### Ce qu'on évite

- **Fausse profondeur** (Spore post-cellule) : promettre une simulation rigoureuse puis livrer des mécaniques de RTS arcade. Primordia doit rester honnête sur son niveau de simulation à chaque couche.
- **Complexité opaque** (DF sans interface) : le modèle de Dwarf Fortress est brillant mais illisible sans wiki externe. Primordia doit visualiser ce qui se passe, pas juste simuler.
- **Performance sacrifiée pour le "réalisme"** (Species ALRE) : des centaines d'agents avec réseau de neurones = framedrops constants. Adopter une approche LOD (Level of Detail) biologique : cerveau complet pour les agents proches/focusés, automates simples pour la masse.
- **Manque de feedback** (Ecosystem) : le joueur observe mais n'interagit pas suffisamment. Trouver le bon curseur entre "dieu passif" et "ingénieur actif".
- **Génétique trop simplifiée** (Niche) : mécaniques éducatives mais peu de profondeur émergente. Ne pas sacrifier la rigueur pour l'accessibilité — trouver un UI qui expose la complexité progressivement.
- **Ambitions > exécution** (Thrive) : attention aux feature creep. Scope clair et livrable par milestone.

### Innovations possibles pour Primordia

1. **Simulation chimique en couche basse** inspirée de The Powder Toy : nutriments, toxines, O2/CO2 comme particules avec diffusion physique réelle dans l'environnement 2D.
2. **Évolution observable et rejouable** : enregistrer l'arbre phylogénétique comme Ecosystem, permettre le "replay" d'une branche évolutive.
3. **Anatomie par calque** à la Dwarf Fortress mais visualisée : zoom sur un organisme = vue anatomique en layers (membrane, cytoplasme, organites, ADN).
4. **Modèle épidémique intégré** à la Plague Inc mais dans l'autre sens — le joueur joue l'écosystème, les pathogènes émergent et évoluent de façon autonome.
5. **LOD cognitif** : agents avec capacité neurale réelle au premier plan, comportements scriptés probabilistes pour la masse hors focus.

---

## Analyse par jeu

---

### 1. Plague Inc (Ndemic Creations, 2012)

**Genre** : Simulation stratégique — pathogène vs humanité
**Plateforme** : Mobile, PC, Switch

#### Mécaniques clés

- **Modèle épidémiologique SIR** (Susceptible → Infected → Recovered/Dead) simplifié mais fonctionnel
- **Arbre de mutations** en 3 branches : Transmissibilité, Symptômes, Résistance — chaque nœud a un coût en ADN
- **Propagation géographique** : carte du monde avec routes aériennes, maritimes, frontalières — vecteurs de transmission explicites
- **Pression de l'humanité** : la cure progresse en parallèle — tension permanente entre vitesse d'infection et visibilité du pathogène
- **Mutations aléatoires** : des traits peuvent apparaître spontanément, forçant le joueur à gérer des évolutions non désirées
- **Adaptation climatique** : certains traits améliorent la survie en zones froides, chaudes, humides

#### Points forts

- Tension mécanique extrêmement bien calibrée : il est rare de gagner facilement, jamais impossible
- L'arbre de mutations est lisible en un coup d'œil — coût, effet, dépendances clairs
- Le feedback visuel sur la carte (rouge se répandant) est satisfaisant et informatif simultanément
- Le meta-jeu de choisir *quand* révéler les symptômes (garder le pathogène silencieux au début) est profond malgré son apparente simplicité
- Différents types de pathogènes (virus, bactérie, prion, parasite) avec des règles légèrement différentes — rejouabilité

#### Points faibles

- Modèle SIR trop simplifié : pas de co-infections, pas de seuil d'immunité collective réaliste, pas de surcharge hospitalière modélisée
- Pas de co-évolution pathogène/hôte : les humains ne développent pas de résistances individuelles, juste une cure globale
- Manque de sous-population (immunodéprimés, personnes âgées, groupes à risque)
- L'aléatoire des mutations peut frustrer : perdre parce qu'un trait coûteux est apparu au mauvais moment
- Pas de simulation des vecteurs (insectes, animaux) sauf dans les DLC

#### Ce que Primordia peut en apprendre

- **L'arbre de traits visible avec coûts clairs** est un pattern UI fondamental à adopter pour l'arbre génomique
- **La tension antagoniste** (hôte vs pathogène, proie vs prédateur) comme moteur de progression
- La carte de propagation avec vecteurs explicites est transposable à la diffusion chimique dans un biome 2D
- Le modèle de **mutations non désirées** qui émergent aléatoirement est réaliste et crée des situations intéressantes

---

### 2. Species: Artificial Life, Real Evolution (Quentin Pradet, 2013+)

**Genre** : Simulation d'évolution en temps réel
**Plateforme** : PC (Early Access Steam, développeur solo)

#### Mécaniques clés

- **Génome vectoriel** : chaque créature a un génome encodant morphologie (taille, longueur des membres, vitesse) et comportements
- **Sélection naturelle pure** : pas d'intervention directe du joueur — le terrain, la nourriture et les prédateurs font la sélection
- **Arbre phylogénétique en temps réel** : visualisation de l'arbre d'évolution qui se construit pendant la partie
- **Spéciation automatique** : quand deux populations divergent suffisamment, Species les déclare espèces séparées
- **Cartes personnalisables** : biomes avec nourriture, prédateurs NPC, obstacles physiques
- **Outils de visualisation** : graphiques de population, distribution des traits, carte de chaleur des zones habitées
- **Mode "god"** : le joueur peut placer nourriture, créer barrières, intervenir comme force environnementale

#### Points forts

- L'arbre phylogénétique live est fascinant — voir l'évolution se ramifier en temps réel est une expérience unique
- La simulation est honnête : pas de progression garantie, des lignées s'éteignent, des "accidents" évolutifs se produisent
- Les graphiques de traits au fil du temps permettent de lire la pression de sélection
- Grande liberté de configuration des conditions initiales
- Communauté active qui partage des scénarios

#### Points faibles

- **Performance catastrophique** à haute population : chaque créature a un réseau de neurones minimal mais ça s'accumule
- Manque de depth génétique : le génome est un vecteur numérique continu, pas un système à allèles/dominance
- Pas de co-évolution complète : prédateurs NPC scriptés, pas vraiment évolutifs
- Rendu très basique — des blobs avec des pattes, peu de feedback visuel sur ce qui se passe biologiquement
- Développement lent (solo dev), Early Access depuis des années
- Manque d'objectif ou de narration : c'est un screensaver fascinant mais peu engageant sur la durée

#### Ce que Primordia peut en apprendre

- **L'arbre phylogénétique comme élément UI central** : c'est la feature la plus impressionnante, à intégrer nativement
- La **spéciation automatique** avec critères explicites est un mécanisme clé à implémenter
- Les **graphiques de traits dans le temps** pour lire la pression de sélection — indispensable pour que le joueur comprenne ce qui se passe
- La **leçon de performance** : le LOD cognitif est non-négociable. Réseau de neurones complet seulement pour agents focusés
- Le **mode dieu** comme outil de curation de l'environnement plutôt que de contrôle direct des créatures

---

### 3. Ecosystem (Nick Walton, 2019+)

**Genre** : Simulation d'évolution neurale
**Plateforme** : PC (Early Access Steam)

#### Mécaniques clés

- **Réseau de neurones évolutif** : chaque créature a un petit réseau de neurones (inputs sensoriels → outputs moteurs) qui évolue avec la morphologie
- **Morphologie procédurale** : corps, nageoires, appendices évoluent librement — formes émergentes souvent biologiquement plausibles
- **Environnement aquatique 3D** : simulation fluide, lumière, particules nutritives
- **Sélection par survie** : manger, ne pas être mangé, se reproduire — fitness définie uniquement par la survie
- **Pas d'intervention joueur** : simulation pure, le joueur est observateur
- **Outils d'analyse** : arbre évolutif, graphiques de population, inspection individuelle des réseaux de neurones
- **Rendu soigné** : éclairage volumétrique, effets de refraction, animations fluides malgré la nature procédurale

#### Points forts

- **Rendu visuellement époustouflant** pour une simulation procédurale — des créatures qui nagent de façon convaincante
- Les cerveaux évolutifs produisent des comportements genuinement émergents et surprenants
- L'inspection d'un réseau de neurones individuel est une feature pédagogique rare
- La morphologie co-évolue avec le comportement — une créature rapide développe des nageoires différentes d'une créature lente
- Excellent générateur de curiosité et d'émerveillement

#### Points faibles

- **Passivité totale du joueur** : il n'y a rien à faire sauf regarder. Pas d'objectif, pas de décision
- Performance limitée : quelques centaines d'agents max dans des conditions raisonnables
- Pas de modèle génétique explicite — le réseau de neurones est la seule variable évolutive
- Pas de feedback sur *pourquoi* telle forme émerge : difficile de relier cause (pression) et effet (morphologie)
- Développement très lent, certaines features promises depuis longtemps

#### Ce que Primordia peut en apprendre

- **Co-évolution morphologie + comportement** : la forme et le cerveau doivent co-évoluer, pas être indépendants
- **L'inspection individuelle** d'un organisme (voir son réseau, son génome, ses stats vitales) est une feature de qualité
- **Le rendu soigné est un multiplicateur** : même un blob convainc si son animation reflète la physique
- **Le feedback causal** manque — Primordia doit explicitement montrer le lien pression de sélection → trait sélectionné
- L'**équilibre observateur/acteur** est à résoudre : Primordia doit donner au joueur des leviers sans trahir la simulation

---

### 4. Spore — Phase cellulaire (Maxis/EA, 2008)

**Genre** : Évolution arcade (phase cellulaire uniquement considérée)
**Plateforme** : PC, Mac

#### Mécaniques clés

- **Jeu d'arcade vue de dessus** dans une soupe primordiale 2D
- **Collecte de nourriture** pour croître — viande (carnivore) ou plantes (herbivore) ou les deux (omnivore)
- **Pièces de corps récupérables** sur les créatures mangées : bouche, yeux, appendices — chacune avec des stats
- **Croissance par points** : atteindre des seuils de taille pour passer à la génération suivante
- **Éditeur de créature** léger mais symboliquement satisfaisant entre les générations
- **Prédateurs et proies** définis par la taille relative — simple et lisible
- **Symboles de cellules** : chaque type d'organite ou de pièce est un glyphe visuel reconnaissable

#### Points forts

- Accessibilité parfaite : n'importe qui comprend en 30 secondes
- L'**éditeur de créature** entre les générations crée un attachement immédiat à son organisme
- La **lecture visuelle instantanée** des autres organismes (grands = dangereux, petits = proies) est un design brillant
- La progression de taille donne un sens constant d'évolution et de puissance croissante
- Phase courte (~30 min) mais mémorable — souvent citée comme la meilleure phase du jeu

#### Points faibles

- **Zéro profondeur biologique** : les "mutations" sont des acquisitions d'items, pas une évolution réelle
- La sélection naturelle n'existe pas : le joueur décide tout, sans pression
- Les pièces de corps sont des buffs de stats, pas des adaptations — aucune émergence
- La transition vers les phases suivantes détruit la promesse de la phase cellulaire (les autres phases sont beaucoup plus superficielles)
- L'édition de créature est purement cosmétique — les stats sont sur les pièces, pas sur la forme
- Pas de génétique, pas de transmission, pas de population

#### Ce que Primordia peut en apprendre

- **L'attachement à son organisme** via l'éditeur/visualisation est un outil puissant d'engagement — même symbolique
- **La lisibilité instantanée** des relations proie/prédateur par signal visuel (taille, couleur, forme) est un principe UI à garder
- **Ne pas promettre la biologie et livrer de l'arcade** — la déception Spore est une leçon d'honnêteté de game design
- La **phase 2D vue de dessus** en soupe primordiale est visuellement et mécaniquement satisfaisante — bon référent pour Primordia
- L'**éditeur comme outil de lecture** (voir sa créature assemblée) peut être adapté en "inspecteur anatomique" interactif

---

### 5. Dwarf Fortress — Couche biologique (Bay 12 Games, 2006+)

**Genre** : Simulation de survie/gestion — simulation biologique parmi les plus poussées du medium
**Plateforme** : PC (gratuit), Steam (version graphique payante)

#### Mécaniques clés

- **Anatomie par tissue** : chaque créature est définie par une liste d'organes, os, muscles, tendons, nerfs — chacun avec des propriétés matérielles
- **Système de blessures par tissu** : une attaque peut percer la peau → muscle → os → organe, avec effets en cascade
- **Maladies et infections** : blessures ouvertes peuvent s'infecter, propagation de maladies entre individus du fort
- **États corporels** : saignement (interne/externe), inconscience, choc, noyade, brûlures, empoisonnements
- **Système nerveux modélisé** : certaines blessures causent paralysie partielle (bras, jambe) selon le nerf touché
- **Métabolisme** : faim, soif, sommeil, gestion de la chaleur corporelle (hypothermie/hyperthermie)
- **Vieillissement** : les créatures ont des durées de vie, certaines maladies liées à l'âge
- **ADN rudimentaire** : héritage de traits physiques parents→enfant (couleur des yeux, taille, etc.)
- **Écosystème** : prédateurs, proies, migrations saisonnières, comportements d'évitement

#### Points forts

- **Niveau de détail anatomique sans équivalent** dans un jeu commercial — référence absolue du genre
- Les blessures en cascade créent des situations narratives organiques et mémorables
- La modélisation par matériaux (os vs métal vs cuir) permet des interactions physiques réalistes
- Les infections ajoutent une couche de menace biologique avec de vraies conséquences
- L'écosystème est cohérent : des espèces disparaissent réellement si surexploitées

#### Points faibles

- **Illisibilité totale** : tout se passe en texte dans des logs, zéro visualisation de l'anatomie
- Impossible de comprendre ce qui se passe biologiquement sans wiki externe
- Performance dégradée sur les forts anciens (tout est simulé en permanence)
- La richesse biologique est un accident de système, pas un feature visible — le joueur n'en profite pas pleinement
- Courbe d'apprentissage prohibitive

#### Ce que Primordia peut en apprendre

- **Adopter le modèle anatomique par tissues** mais le **visualiser** — c'est la grande opportunité manquée de DF
- Le **système de blessures en cascade** (membrane → cytoplasme → organite) est transposable à l'échelle cellulaire
- Les **états physiologiques discrets** (saignement, infection, choc) avec effets en cascade sont une richesse narrative
- **Simuler les matériaux** : une membrane lipidique a des propriétés différentes d'une paroi cellulaire rigide
- Le principe de **simulation complète en arrière-plan** est viable si le front-end visualise correctement

---

### 6. Niche — A Genetics Survival Game (Team Niche, 2016)

**Genre** : Simulation de génétique + survie au tour par tour
**Plateforme** : PC, Mac, Linux — Steam

#### Mécaniques clés

- **Modèle de génétique Mendélienne** : allèles dominants et récessifs sur des loci définis
- **Gènes visibles sur chaque animal** : fourrure, oreilles, morphologie — chaque trait est encodé par 1-2 allèles
- **Sélection naturelle dirigée par l'environnement** : biomes froids favorisent la fourrure épaisse, etc.
- **Arbre généalogique** : visualisation des lignées, détection de consanguinité
- **Population management** : resources limitées, prédateurs, maladies — pression de sélection constante
- **Dérive génétique** : petites populations perdent de la diversité génétique, risque d'extinction
- **Mutations aléatoires** : nouveaux allèles peuvent apparaître, parfois neutres, parfois bénéfiques/délétères
- **Mode éducatif** : conçu avec des biologistes pour être scientifiquement honnête

#### Points forts

- **Génétique Mendélienne correctement implémentée** — un des rares jeux à le faire rigoureusement
- La **visibilité du génotype** (voir les allèles de chaque animal) est une feature pédagogique excellente
- Les **concepts de dérive génétique et consanguinité** sont réellement présents et impactants
- Interface claire malgré la complexité sous-jacente
- Bon équilibre entre accessibilité (tour par tour, pas trop rapide) et profondeur génétique
- Validation scientifique par des biologistes

#### Points faibles

- **Tour par tour = pas de dynamique temps réel** — les interactions écosystémiques sont simplifiées
- Nombre limité de loci génétiques (quelques dizaines) — le génome est peu complexe
- Pas de génétique des populations au sens statistique (Hardy-Weinberg, etc.)
- Pas de co-évolution entre espèces : chaque espèce évolue dans son silo
- Rendu 2D cartoon — n'appuie pas sur l'aspect scientifique visuellement
- Le gameplay de survie prime parfois sur la profondeur biologique

#### Ce que Primordia peut en apprendre

- **La visibilité du génotype sur chaque individu** est un standard à viser — le joueur doit pouvoir inspecter les allèles
- Le **modèle diploïde avec dominance** est la bonne base génétique — l'implémenter rigoureusement
- La **dérive génétique sur petites populations** est une mécanique de profondeur que Primordia doit intégrer
- La **validation avec des biologistes** est un gage de qualité — documenter les choix scientifiques dans Primordia
- **Tour par tour n'est pas nécessaire** pour rendre la génétique lisible — des pauses/slowmo suffisent

---

### 7. Thrive (Revolutionary Games Studio, 2012+)

**Genre** : Simulation évolutive microbiologique open source
**Plateforme** : PC, Mac, Linux — gratuit sur GitHub/itch.io

#### Mécaniques clés

- **Phase microbiologique jouable** : contrôle d'un protiste en vue top-down, collecte d'ATP via organites
- **Éditeur cellulaire** : placer des organites sur un hexagrid — chacun a une fonction (chloroplaste = photosynthèse, mitochondrie = ATP, flagelle = mobilité)
- **Simulation des composés chimiques** : glucose, ATP, O2, CO2, ammoniaque — chacun a une densité dans l'environnement
- **Processus biologiques** : photosynthèse, respiration, fermentation — avec les vraies équations chimiques
- **Évolution dirigée par le joueur** : à chaque génération, le joueur édite sa cellule en dépensant des "points d'évolution"
- **Micro-écosystème** : d'autres espèces évoluent en parallèle (IA), interactions compétitives/symbiotiques
- **Patches environnementaux** : différentes zones avec différentes concentrations chimiques, température, lumière

#### Points forts

- **Honnêteté scientifique exemplaire** : les processus métaboliques sont biologiquement corrects
- L'**éditeur d'organites sur hexagrid** est ingénieux — placement spatial = fonction différente selon voisinage
- La simulation chimique avec diffusion réelle est une base technique solide
- Open source = code inspectable et moddable
- Ambition et scope clairs documentés (roadmap jusqu'à la phase macroscopique)
- La **co-évolution des espèces IA** est déjà fonctionnelle

#### Points faibles

- **Performance très limitée** : la simulation chimique détaillée est coûteuse
- La **phase micro est la seule phase vraiment jouable** — les phases suivantes (plantes, animaux) sont embryonnaires après 10+ ans
- Développement très lent (bénévoles) — les milestones glissent
- L'**éditeur cellulaire bloque la sélection naturelle** : le joueur choisit son évolution, l'environnement ne sélectionne pas vraiment
- Rendu passable — fonctionne mais pas impressionnant visuellement
- Manque de feedback sur la pression de sélection : pourquoi tel organite devient avantageux ?

#### Ce que Primordia peut en apprendre

- **L'hexagrid pour le placement d'organites** est une mécanique UI élégante à considérer
- La **simulation chimique par diffusion** est la bonne approche pour modéliser l'environnement — voir The Powder Toy
- **Ne pas bloquer la sélection naturelle** avec l'éditeur : Primordia peut avoir un éditeur mais la sélection doit rester autonome
- L'**honnêteté des équations biochimiques** (ATP, NAD+, etc.) est un standard à viser pour la couche métabolique
- Le **code open source** est une référence technique directement inspectable pour les mécaniques de base

---

### 8. The Powder Toy (Simon Robertshaw + communauté, 2008+)

**Genre** : Simulation physique par automates cellulaires / particules
**Plateforme** : PC, Mac, Linux — gratuit, open source

#### Mécaniques clés

- **Grille de particules** : chaque pixel est une particule avec un type (eau, feu, acide, métal, gaz, etc.)
- **Automates cellulaires** : chaque type de particule a des règles de comportement avec ses voisins
- **Simulation de chaleur** : chaque particule a une température, la chaleur se propage par conduction/convection/radiation
- **Réactions chimiques** : acide + métal = corrosion, eau + électricité = électrolyse, bois + feu = combustion — des centaines de combinaisons
- **Physique des gaz et liquides** : pression, viscosité, densité, diffusion
- **Électricité** : conducteurs, semi-conducteurs, interrupteurs, métal fondu
- **Vie** : des particules "LIFE" implémentent des automates cellulaires type Game of Life ou règles custom
- **Éditeur libre** : dessiner avec n'importe quel élément, sauvegarder, partager
- **Moddabilité** : langage Lua pour créer de nouveaux éléments avec des règles custom
- **Communauté** : bibliothèque de milliers de constructions partagées

#### Points forts

- **Simulation physique emergente remarquable** : des comportements complexes émergent de règles simples
- Performance excellente malgré la richesse : optimisé pour des millions de particules
- **Moddabilité totale** via Lua — la communauté a créé des éléments biologiques, des circuits logiques, etc.
- Interface minimaliste mais suffisamment expressive
- La bibliothèque communautaire est une forme de créativité collective fascinante
- **Le sand game paradigm** — intuitivement compréhensible, infiniment extensible

#### Points faibles

- **Pas d'évolution** : les règles sont fixes, aucune adaptation au fil du temps
- Pas d'agents avec comportements autonomes : les particules suivent des règles mais n'ont pas d'objectifs
- Rendu pixelisé fixe — pas de zoom sémantique
- Pas de notion de temps biologique — tout est instantané au niveau physique

#### Ce que Primordia peut en apprendre

- **Le paradigme automates cellulaires pour l'environnement** est la base technique à adopter pour la couche physico-chimique
- Les **particules chimiques avec diffusion** (O2, CO2, glucose, toxines) modélisent l'environnement cellulaire de façon réaliste et performante
- **Règles locales → comportements globaux** : l'émergence par règles simples est le principe unificateur de Primordia
- La **performance à haute densité** de particules est un objectif technique — utiliser des grilles chunked comme TPT
- Le **Lua modding** pour les règles d'éléments est un pattern qui permettrait une communauté de moddeurs biologistes
- La **bibliothèque de constructions** est un modèle de partage communautaire — à adapter en "génomes sauvegardables"

---

## Matrice comparative

| Jeu | Génétique | Évolution | Simulation env. | Performance | Feedback visuel | Interaction joueur |
|---|---|---|---|---|---|---|
| Plague Inc | ★★☆ | ★★☆ | ★★★ | ★★★★★ | ★★★★ | ★★★★★ |
| Species ALRE | ★★☆ | ★★★★ | ★★★ | ★★☆ | ★★☆ | ★★★ |
| Ecosystem | ★☆☆ | ★★★★ | ★★★ | ★★★ | ★★★★★ | ★★☆ |
| Spore (cell) | ★☆☆ | ★☆☆ | ★★☆ | ★★★★★ | ★★★★ | ★★★★★ |
| Dwarf Fortress | ★★★★ | ★★☆ | ★★★★ | ★★★ | ★☆☆ | ★★★★ |
| Niche | ★★★★★ | ★★★ | ★★★ | ★★★★★ | ★★★★ | ★★★★ |
| Thrive | ★★★★ | ★★★ | ★★★★★ | ★★★ | ★★★ | ★★★★ |
| The Powder Toy | ★☆☆ | ★☆☆ | ★★★★★ | ★★★★★ | ★★★★ | ★★★★★ |
| **Primordia (cible)** | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★ | ★★★★★ | ★★★★ |

---

## Décisions techniques déduites de cette analyse

1. **Génome diploïde** à allèles dominants/récessifs (modèle Niche) + extension quantitative (polygénique) pour les traits continus
2. **Automates cellulaires pour l'environnement** (modèle Powder Toy) : particules chimiques avec diffusion, pas de simulation continue coûteuse
3. **LOD cognitif** (leçon Species/Ecosystem) : réseau de neurones minimal pour agents focusés, Finite State Machine probabiliste pour la masse
4. **Arbre phylogénétique live** (modèle Species) comme élément central de l'interface
5. **Inspecteur anatomique** par couches (modèle DF visualisé) : cliquer sur un organisme = voir sa membrane, organites, ADN
6. **Éditeur d'organites** inspiré de Thrive (hexagrid) mais la sélection reste autonome — l'éditeur est un outil de lecture, pas de contrôle
7. **Modèle épidémique intégré** dans le sens bottom-up : les pathogènes émergent de la simulation comme les autres agents
8. **Métabolisme par équations biochimiques** (standard Thrive) : ATP, NADH, CO2, glucose — honnêteté scientifique
