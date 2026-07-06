# Silencia — Stratégie marketing

> **Statut :** document de travail — v1, rédigé le 6 juillet 2026.
> **Périmètre :** France uniquement, iOS. Produit = app **payante à l'achat unique** sur l'App Store
> (à vie, **pas** un abonnement, **pas** un achat intégré / freemium).
> **Sources :** synthèse d'une recherche multi-sources vérifiée (voir §8). Les faits notés
> « vérifié » ont passé une vérification contradictoire ; les points notés ⚠️ sont des
> hypothèses non validées, à défricher avant d'engager du budget.

---

## 1. Résumé exécutif

Le marché est massif et prouvé : **9 Français sur 10** restent excédés par le démarchage
malgré la loi, et la France a **le taux de spam-calls le plus élevé d'Europe**. Un concurrent
quasi-identique (**Saracroche**, blocage déterministe via plages Arcep + CallKit) a atteint
**~800 000 à 1 M d'utilisateurs** avec une note de **4,9/5** — preuve que le modèle produit
fonctionne à grande échelle.

**Le levier n°1 est réglementaire :** la **loi n° 2025-594 du 30 juin 2025** fait basculer la
France de l'opt-out (Bloctel) vers l'**opt-in obligatoire le 11 août 2026**, date à laquelle
**Bloctel disparaît**. C'est un pic d'attention médiatique national sur exactement notre sujet.

**Décision structurante :** ne pas courir au 11 août avec un produit sans avis. Utiliser le
pic pour **construire** (liste d'attente, presse, avis seedés), puis **lancer réellement en
septembre-octobre**, sur la vague « la loi ne suffit pas » — moment où la douleur, donc
l'intention d'achat, culmine.

**Les deux leviers décisifs :** (a) la **fiche App Store / ASO** (seul argumentaire de vente
en achat-upfront), (b) le **canal senior de confiance** (mutuelles, presse senior,
partenariats) — c'est lui qui rend un paiement à froid acceptable face à un concurrent gratuit.

---

## 2. Positionnement

- **Promesse de marque :**
  *« Le démarchage, bloqué pour de bon. Un seul achat, à vie. Aucun abonnement, aucune donnée. »*
- **Positionnement concurrentiel :** le blocage qui **marche vraiment**, là où **Bloctel a
  échoué** et où **Orange fait payer un abonnement**.
- **Preuves de différenciation :**
  - Blocage **déterministe** (plages Arcep) vs crowdsourcing heuristique.
  - **Achat unique à vie**, pas d'abonnement (vs Orange Cybersecure à 7 €/mois).
  - **Aucune donnée collectée**, traitement 100 % on-device → *« Vous payez une fois, vous
    n'êtes jamais le produit. »* (retourne le « si c'est gratuit, c'est vous le produit »
    contre Saracroche/dons, Truecaller/data, apps à pub).

### Ce que change le modèle « achat unique » (vs le freemium initialement envisagé)

| Effet | Conséquence marketing |
|---|---|
| Plus de free tier bancal (2 plages) | Comparaison plus propre : « gratuit crowdsourcé » vs « payé, à vie, sans data » |
| Argument « à vie, sans abonnement » | Arme frontale contre Orange (7 €/mois) et la fatigue de l'abonnement |
| Pas d'essai gratuit | **Toute la vente se joue sur la fiche App Store + les avis + la confiance avant achat** |
| Bouche-à-oreille freiné (« achète-le » ≠ « c'est gratuit ») | À compenser par le **cadeau** (offrir à ses parents) et le parrainage |
| Terrain « Top Payant » | Moins de volume, mais Saracroche (gratuit) n'y figure pas |

---

## 3. Cibles

1. **Seniors via canaux de confiance = le segment qui rapporte.**
   Fortement exposés (arnaques, harcèlement), mais n'iront jamais comparer sur l'App Store.
   Un paiement à froid passe **s'il est recommandé/installé par un tiers de confiance**
   (mutuelle, presse senior, proche). Pour eux, **la distribution et la confiance SONT la
   différenciation** — pas la technologie.

2. **Grand public agacé = le volume et la crédibilité.**
   Reach peu coûteux via App Store organique + PR autour de la loi. Conversion plus faible
   (ils comparent, tombent sur le gratuit) → ne pas y mettre d'acquisition payante frontale
   tant que l'économie unitaire n'est pas prouvée.

---

## 4. Le cadrage temporel (la décision clé)

On est le **6 juillet 2026**. Pivot de la loi = **11 août 2026** (dans ~5 semaines).

**Ne pas lancer pour le 11 août**, pour deux raisons :

1. **Une app payante sans avis ne convertit pas.** Sans essai gratuit, l'acheteur se fie aux
   notes. Lancer le 11 août avec 0 avis = cramer la meilleure fenêtre PR sur une fiche morte.
2. **La douleur culmine *après* la loi.** Le 11 août, les gens espèrent que ça s'arrête.
   Fin août / septembre, ils réalisent que **les appels continuent** (numéros Arcep, offshore,
   faux consentements). C'est là que les journalistes écrivent le papier « la loi n'a rien
   changé » et que le consommateur cherche activement une solution.

→ **Le 11 août sert à capter et construire. Le lancement réel vise septembre-octobre.**

⚠️ Ce calendrier suppose l'app prête à shipper vers **mi-septembre**. Si le produit n'est pas
prêt, tout glisse — mais la vague « la loi ne suffit pas » reste exploitable tout l'automne.
**Ne jamais lancer sans avis seedés.**

---

## 5. Calendrier en 4 phases

| Phase | Dates | Objectif | Actions |
|---|---|---|---|
| **0 — Pré-lancement** | **6 juil → 10 août** | Construire les munitions | Fiche App Store + ASO finalisées ; **bêta TestFlight (50-100 users)** pour de **vrais avis dès J1** ; landing page + **liste d'attente email** ; prise de contact **presse & partenaires** ; produire le **contenu explicatif de la loi** |
| **1 — Le pic média** | **11 août (+ sa semaine)** | Capter l'attention (pas vendre à vide) | PR réactive « la loi change aujourd'hui — voici pourquoi ça ne suffira pas » ; pousser vers la **landing/waitlist**, pas vers une fiche sans avis |
| **2 — Lancement réel** | **mi-sept → oct** | Vendre sur la vague « ça ne marche pas » | **Lancement public** (avis seedés) ; **PR vague 2** « 1 mois après, les appels continuent » ; **activation canal senior** ; pitch **App Store featuring** |
| **3 — Scale & cadeau** | **nov → déc** | Volume + résoudre le bouche-à-oreille | Campagne **« Offrez la tranquillité à vos parents »** (Noël) ; premiers **tests d'acquisition payante** (petits, mesurés) |
| **4 — Régime de croisière** | **2027+** | Entretien | Parrainage, SEO, pics saisonniers, presse récurrente |

---

## 6. Les campagnes

### Campagne A — « La loi explique » (SEO + social)
- **Quand :** publier avant le 11 août, pousser fort autour du 11.
- **Quoi :** page pilier *« Démarchage : ce qui change le 11 août 2026 (et pourquoi les appels
  ne vont pas s'arrêter) »* + déclinaisons courtes (carrousels Facebook, Reels).
- **Pourquoi :** aimant à trafic gratuit sur les recherches qui explosent autour du pivot.
  Chaque visiteur → liste d'attente.
- **KPI :** inscrits waitlist, trafic organique.

### Campagne B — « Relations presse, 2 vagues »
- **Vague 1 (autour du 11 août) :** pitch conso/tech + presse senior, angle *« la solution
  technique »*.
- **Vague 2 (fin sept) :** *« 1 mois après la loi : les Français toujours harcelés »* — le
  papier que les journalistes veulent écrire, la démo tombe pile.
- ⚠️ **Presse senior (Notre Temps, Pleine Vie…) : bouclage 6-8 semaines avant parution.** Pour
  un numéro d'octobre, **pitcher en août.** Point de calendrier à ne pas rater.

### Campagne C — « Fiche App Store & ASO » (socle permanent)
- **Quand :** prêt avant le lancement.
- **Quoi :** titre + sous-titre optimisés (« bloquer démarchage », « anti démarchage »,
  « à vie sans abonnement ») ; captures qui vendent *« un seul achat »* et *« aucune donnée »* ;
  réponses aux avis.
- **Pourquoi :** unique argumentaire de vente en achat-upfront. Viser le classement **Top Payant**.

### Campagne D — « Canal senior de confiance » (le cœur du chiffre)
- **Quand :** contacts en juillet-août, activation sept-oct.
- **Quoi :** partenariats **mutuelles / assurances / associations de conso / presse senior** ;
  format *« recommandé / offert / configuré pour vous »*.
- **Pourquoi :** rend un **paiement à froid** acceptable pour un senior face à un concurrent
  gratuit. **Sans ce canal, le modèle payant plafonne.**
- ⚠️ Non validé par la recherche (quels partenaires, quels coûts) → à défricher.

### Campagne E — « Offrez la tranquillité » (Noël)
- **Quand :** nov-déc.
- **Quoi :** positionner l'achat **comme cadeau des enfants aux parents/grands-parents.**
- **Pourquoi :** contourne le frein du bouche-à-oreille (l'ambassadeur ne peut pas dire « c'est
  gratuit »). Le cadeau = paiement + confiance + installation d'un coup. **Format le plus
  aligné avec le modèle payant.**

### Campagne F — « Acquisition payante » (à retarder)
- **Quand :** **pas avant** d'avoir mesuré la conversion réelle (T4 au plus tôt).
- **Pourquoi :** payer des clics vers une fiche posée à côté d'un gratuit 4,9 = économie
  unitaire risquée. Tester petit, une fois le coût d'acquisition soutenable connu.

---

## 7. Priorités, budget & mesure

**Priorités par rapport impact/coût :**
1. **Gratuit et vital :** avis seedés (bêta), ASO, contenu loi, PR (temps > argent).
2. **Effort commercial, pas cash :** partenariats senior — meilleure monétisation, coût = temps de négo.
3. **Petit cash saisonnier :** campagne cadeau de Noël.
4. **Cash à valider en dernier :** acquisition payante.

**À mesurer en continu :**
- inscrits waitlist → installs payantes (taux de conversion)
- note App Store (garder > 4,5)
- coût d'acquisition par canal
- part des ventes : canal senior vs App Store organique

---

## 8. Base factuelle (recherche vérifiée)

Faits ayant passé la vérification contradictoire :

- **Réglementaire :** loi n° 2025-594 du 30 juin 2025 → opt-in obligatoire le **11 août 2026**,
  fin de Bloctel à cette date. Démarchage déjà restreint depuis le 1er mars 2023 (lun-ven
  10h-13h / 14h-20h, interdit week-ends et jours fériés).
  *Sources : service-public.gouv.fr, economie.gouv.fr, Légifrance.*
- **Demande :** 9 Français sur 10 exaspérés (UFC-Que Choisir) ; France = taux de spam-calls le
  plus élevé d'Europe (Hiya 2023). Bloctel jugé inefficace par la DGCCRF et un rapport du
  Sénat 2024.
- **Concurrence :**
  - **Saracroche** — gratuit, open-source (GPLv3), ~15-16 M numéros Arcep + CallKit, 4,9/5
    (7 500+ avis), #3 Utilitaires, **~800 k à 1 M+ users**, zéro collecte de données.
  - **Orange Téléphone** (leader) — depuis le 6 juin 2024, **plus de blocage automatique par
    défaut** ; fonction déplacée derrière **Orange Cybersecure (7 €/mois**, clients Orange/Sosh).
  - **Anti SPAM (Gingko Lab, Bordeaux)** — modèle proche, mêmes préfixes Arcep.

### ⚠️ À NE PAS utiliser (réfuté en vérification)
- Le **prix « à vie » du concurrent (~4,99 €)** — non confirmé. Ne pas s'y ancrer pour fixer
  notre prix.
- Les **benchmarks « hard paywall vs freemium »** de RevenueCat (conversion 12 % vs 2 %, LTV ×2)
  — rejetés. Ne fonder aucune décision de prix dessus.
- Les **chiffres Whoscall** (70 M users, etc.) — source non fiable.
- Le **97 % agacés** — chiffre déclaratif d'une association militante (méthodo non publiée) :
  à présenter comme tel, pas comme étude neutre. Le « 9 sur 10 » est plus solide.
- Nuance Orange : le blocage **manuel** reste réactivable gratuitement ; dire précisément
  « plus de blocage automatique par défaut » et « payant hors Orange/Sosh ».

### ⚠️ Angles morts (non validés par la recherche)
Aucune source primaire n'a confirmé les **canaux d'acquisition** spécifiques (ASO français,
Facebook vs autres réseaux, presse senior, partenariats mutuelles/assurances). Ces pistes
restent des hypothèses — à valider par nos propres tests.

---

## 9. Questions ouvertes à trancher

1. **Quel prix de l'achat unique ?** Saracroche gratuit exerce une pression déflationniste.
   Le prix concurrent et les benchmarks de conversion ayant été réfutés → à tester nous-mêmes.
2. **Quels canaux performent vraiment** pour seniors + grand public en France ? (données
   primaires manquantes)
3. **Comment se différencier durablement de Saracroche** (gratuit, open-source, ~1 M users) ?
   Réponse retenue : par la **distribution + la confiance + le service**, pas la techno.
4. **La douleur persistera-t-elle après le 11 août 2026 ?** Si l'opt-in est contourné, la
   demande reste forte — à surveiller.

---

## 10. Prochains pas

- [ ] Rédiger la **fiche App Store complète** (titre, sous-titre, description, mots-clés ASO,
      script des captures).
- [ ] Défricher le **plan canal senior** (types de partenaires, approche, modèles économiques).
- [ ] Décider du **prix** de l'achat unique (test).
- [ ] Lancer la **bêta TestFlight** pour seeder les avis avant lancement.
