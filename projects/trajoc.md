# TrajOc

**Planificateur de trajets Occitanie — iOS natif**

| | |
|---|---|
| Stack | Swift · SwiftUI · MapKit · Widgets · Background tasks |
| APIs | Navitia · OpenRouteService · JCDecaux · Nominatim |
| iOS | 17+ |
| Repo | https://github.com/PrpleRat/TrajOc |

## Problème résolu

Un seul trajet Occitanie peut mêler TER, métro, bus et vélo en libre-service. TrajOc agrège horaires TC, itinéraires doux et stations vélo sur une carte régionale.

## Fonctionnalités clés

- Itinéraires transports (SNCF, TER, métro, bus) via Navitia
- Piéton / vélo via OpenRouteService
- Stations vélo partagé (Toulouse, Montpellier, Nîmes, Perpignan…)
- Favoris, recherche d’adresses, alertes perturbations
- Widget trajet favori (App Group)

## Architecture

- Clients HTTP typés par fournisseur
- Widget + synchronisation App Group
- Notifications + tâche arrière-plan
- CI : build simulateur + bootstrap signing + TestFlight

## Pourquoi c’est intéressant

- Intégration **multi-API** réelle
- UX mobilité + widgets
- Contexte géographique / produit local fort
