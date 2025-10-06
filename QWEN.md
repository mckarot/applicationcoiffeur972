Instructions
Langue : Toujours répondre en français.

Méthode : Pour les requêtes longues, élaborer une liste de tâches (todo list) pour structurer le processus. Cocher chaque étape au fur et à mesure de la progression.

Style de design : Proposer un design moderne et professionnel avec des animations de transition de page et des animations "hero" pour les widgets.

Contexte du projet : J'ai accès à l'ensemble des fichiers du projet. Mon périmètre d'intervention principal pour le code source est le dossier /lib.

Bonnes pratiques
Après chaque modification de fichier, effectuer une vérification avec l'analyseur Dart (dart analyze) pour s'assurer qu'il n'y a pas d'erreurs ou d'avertissements.

Porter une attention particulière aux problèmes de débordement (overflow) dans les deux orientations, portrait et paysage. S'assurer que les mises en page s'adaptent correctement pour éviter tout contenu tronqué.

Utiliser un SliverAppBar aussi souvent que possible, en particulier pour les longs contenus. Cela améliore considérablement la lisibilité et l'expérience utilisateur en mode paysage grâce à son comportement de défilement flexible.

Gestion des états : Préférer l'utilisation de ChangeNotifier avec Provider pour une gestion d'état simple et efficace. Pour des applications plus complexes, envisager Riverpod ou Bloc. Toujours séparer clairement la logique métier des widgets.

Architecture : Suivre le principe de séparation des responsabilités avec une structure de dossiers claire (models, providers, services, screens, widgets). Les services doivent encapsuler l'accès aux données, les providers gérer l'état, et les widgets se concentrer sur l'UI.

Gestion des erreurs : Implémenter une gestion d'erreurs robuste avec des états d'erreur explicites dans les providers. Utiliser des packages de logging appropriés au lieu de print() en production.

Performance : Éviter les rebuilds inutiles en utilisant const là où c'est possible. Utiliser ListView.builder pour les listes longues. Optimiser les images et les assets. Pour améliorer la fluidité du défilement, ajuster la propriété cacheExtent de ListView.builder pour pré-charger les éléments avant qu'ils ne deviennent visibles. Mettre en cache les images et vidéos pour éviter les téléchargements répétés. Utiliser des packages comme cached_network_image pour gérer le cache automatiquement.

Sécurité : Ne jamais logger d'informations sensibles. Valider toutes les entrées utilisateur. Utiliser des méthodes d'authentification sécurisées. Mettre en place une gestion des permissions appropriée. Chiffrer les données sensibles en local. Utiliser HTTPS pour toutes les communications réseau. Implémenter la protection contre les attaques de type injection. Mettre en place des mécanismes de rate limiting pour prévenir les abus. Utiliser des tokens d'authentification avec expiration. Valider les certificats SSL/TLS.

Maintenabilité : Utiliser des noms de variables et de fonctions explicites. Ajouter des commentaires pertinents pour la logique complexe. Suivre les conventions de nommage Dart.

Tests automatisés : Lorsque cela est pertinent, proposer des exemples de tests automatisés pour les fonctionnalités critiques. Expliquer l'importance des tests automatisés par rapport aux tests manuels, en mettant l'accent sur la non-régression et la détection précoce des bugs.

Tests de performance : Mettre en place des tests de performance réguliers. Surveiller les temps de chargement des écrans critiques. Utiliser les outils de profilage de Flutter pour identifier les goulots d'étranglement. Tester les performances sur différents appareils et conditions réseau.

Bonnes pratiques de codage : Éviter l'utilisation de BuildContext traversant des gaps async sans vérification mounted. Remplacer les API dépréciées dès qu'elles sont identifiées. Utiliser des widgets réutilisables et des extensions pour éviter la duplication de code.

Refactorisation et lisibilité : Identifier et refactoriser régulièrement les parties du code qui deviennent complexes ou dupliquées. Appliquer les principes SOLID et DRY (Don't Repeat Yourself). Extraire les fonctions longues en sous-fonctions avec des noms explicites. Utiliser des classes et des widgets pour encapsuler la logique complexe. Préférer la composition à l'héritage lorsque c'est pertinent. Maintenir une complexité cyclomatique faible dans les fonctions.

Gestion des dépendances : Mettre à jour régulièrement les packages vers leurs versions stables. Éviter les packages peu maintenus ou abandonnés. Vérifier la compatibilité des versions avant les mises à jour majeures. Préférer les packages officiels Flutter lorsque c'est possible.

Internationalisation : Structurer le code pour faciliter l'ajout de nouvelles langues. Utiliser les widgets appropriés pour la localisation. Séparer les textes du code dans des fichiers de traduction.

Accessibilité : S'assurer que l'application est utilisable par les personnes avec des handicaps. Utiliser des labels appropriés pour les éléments UI. Respecter les ratios de contraste pour la lisibilité. Tester avec les outils d'accessibilité de Flutter.

Documentation : Documenter l'architecture du projet dans le README. Expliquer les décisions d'architecture importantes. Maintenir la documentation à jour avec le code. Utiliser des commentaires DartDoc pour les APIs publiques.

Gestion du cycle de vie : Gérer correctement l'initialisation et la libération des ressources. Utiliser les méthodes dispose() pour libérer les contrôleurs et listeners. Gérer les états d'application (pause, resume) quand c'est nécessaire.

Gestion des assets : Optimiser les images et les icônes. Utiliser les formats appropriés (SVG, WebP). Organiser les assets dans une structure claire. Utiliser les thèmes pour les icônes et les couleurs.

Thématisation (Theming) Avancée : Implémenter un système de thème supportant les modes clair et sombre. Centraliser la charte graphique (couleurs, typographies, styles) dans le ThemeData pour garantir la cohérence et faciliter les changements.

Optimisation des coûts Firebase : Minimiser les lectures/écritures inutiles dans Firestore. Utiliser le cache de Firebase pour les données fréquemment consultées. Implémenter des règles de sécurité strictes pour éviter les abus. Surveiller régulièrement l'utilisation des services Firebase pour détecter les anomalies de coût. Utiliser des index composés pour optimiser les requêtes fréquentes.