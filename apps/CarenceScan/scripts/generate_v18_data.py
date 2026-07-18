#!/usr/bin/env python3
"""Generate nutrition JSON files and recettes_v2.json for CarenceScan v1.8."""
import json
from pathlib import Path

RES = Path(__file__).resolve().parent.parent / "CarenceScan" / "Resources"

ALIMENTS = [
    {"id": "sardines", "nom": "Sardines", "emoji": "🐟", "categorie": "poissonsFruitsMer", "carences_couvertes": ["omega3", "vitamine_d", "vitamine_b12", "calcium"], "portion_type": "1 boîte (100g)"},
    {"id": "saumon", "nom": "Saumon", "emoji": "🐠", "categorie": "poissonsFruitsMer", "carences_couvertes": ["omega3", "vitamine_d", "vitamine_b12", "selenium"], "portion_type": "1 pavé (150g)"},
    {"id": "maquereau", "nom": "Maquereau", "emoji": "🐡", "categorie": "poissonsFruitsMer", "carences_couvertes": ["omega3", "vitamine_d", "vitamine_b12", "vitamine_b2_b3"], "portion_type": "1 filet (130g)"},
    {"id": "thon", "nom": "Thon en boîte", "emoji": "🥫", "categorie": "poissonsFruitsMer", "carences_couvertes": ["vitamine_b12", "vitamine_b6", "vitamine_b2_b3", "selenium"], "portion_type": "1 boîte (130g)"},
    {"id": "oeufs", "nom": "Œufs", "emoji": "🥚", "categorie": "viandesOeufs", "carences_couvertes": ["vitamine_d", "vitamine_b12", "zinc", "selenium", "vitamine_b2_b3"], "portion_type": "2 œufs"},
    {"id": "viande_rouge", "nom": "Viande rouge (bœuf/agneau)", "emoji": "🥩", "categorie": "viandesOeufs", "carences_couvertes": ["fer", "zinc", "vitamine_b12", "vitamine_b6", "vitamine_b2_b3"], "portion_type": "1 portion (150g)"},
    {"id": "poulet", "nom": "Poulet / Dinde", "emoji": "🍗", "categorie": "viandesOeufs", "carences_couvertes": ["vitamine_b6", "zinc", "vitamine_b2_b3", "tryptophane"], "portion_type": "1 blanc (150g)"},
    {"id": "foie_volaille", "nom": "Foie de volaille", "emoji": "🫀", "categorie": "viandesOeufs", "carences_couvertes": ["fer", "vitamine_a", "vitamine_b12", "zinc", "vitamine_b9", "vitamine_b2_b3"], "portion_type": "1 portion (100g)"},
    {"id": "epinards", "nom": "Épinards", "emoji": "🥬", "categorie": "legumesVerts", "carences_couvertes": ["fer", "vitamine_b9", "vitamine_k", "magnesium", "vitamine_c"], "portion_type": "1 grosse poignée (80g)"},
    {"id": "brocolis", "nom": "Brocoli", "emoji": "🥦", "categorie": "legumesVerts", "carences_couvertes": ["vitamine_c", "vitamine_k", "vitamine_b9", "vitamine_b6"], "portion_type": "1/2 brocoli (150g)"},
    {"id": "poivrons", "nom": "Poivron rouge", "emoji": "🫑", "categorie": "legumesVerts", "carences_couvertes": ["vitamine_c", "vitamine_a", "vitamine_b6"], "portion_type": "1 poivron (150g)"},
    {"id": "carottes", "nom": "Carottes", "emoji": "🥕", "categorie": "legumesVerts", "carences_couvertes": ["vitamine_a", "vitamine_b9"], "portion_type": "2 carottes (150g)"},
    {"id": "champignons", "nom": "Champignons", "emoji": "🍄", "categorie": "legumesVerts", "carences_couvertes": ["vitamine_d", "vitamine_b2_b3", "zinc", "selenium"], "portion_type": "1 portion (100g)"},
    {"id": "avocat", "nom": "Avocat", "emoji": "🥑", "categorie": "legumesVerts", "carences_couvertes": ["vitamine_b9", "vitamine_k", "omega3", "magnesium"], "portion_type": "1/2 avocat"},
    {"id": "lentilles", "nom": "Lentilles", "emoji": "🫘", "categorie": "legumineuses", "carences_couvertes": ["fer", "vitamine_b1", "vitamine_b9", "magnesium", "zinc"], "portion_type": "1 portion cuite (200g)"},
    {"id": "pois_chiches", "nom": "Pois chiches", "emoji": "🟡", "categorie": "legumineuses", "carences_couvertes": ["fer", "zinc", "vitamine_b6", "vitamine_b9", "magnesium"], "portion_type": "1 portion (150g)"},
    {"id": "amandes", "nom": "Amandes", "emoji": "🌰", "categorie": "oleagineuxGraines", "carences_couvertes": ["magnesium", "calcium", "vitamine_e", "zinc"], "portion_type": "1 petite poignée (30g)"},
    {"id": "noix", "nom": "Noix", "emoji": "🥜", "categorie": "oleagineuxGraines", "carences_couvertes": ["omega3", "magnesium", "zinc", "vitamine_b6"], "portion_type": "5-6 noix (30g)"},
    {"id": "graines_courge", "nom": "Graines de courge", "emoji": "🌱", "categorie": "oleagineuxGraines", "carences_couvertes": ["zinc", "magnesium", "omega3", "fer"], "portion_type": "2 cuillères à soupe (30g)"},
    {"id": "chocolat_noir", "nom": "Chocolat noir 70%+", "emoji": "🍫", "categorie": "oleagineuxGraines", "carences_couvertes": ["magnesium", "fer", "zinc"], "portion_type": "2-3 carrés (30g)"},
    {"id": "kiwis", "nom": "Kiwi", "emoji": "🥝", "categorie": "fruitsVitamineC", "carences_couvertes": ["vitamine_c", "vitamine_k", "vitamine_b9"], "portion_type": "2 kiwis"},
    {"id": "fraises", "nom": "Fraises", "emoji": "🍓", "categorie": "fruitsVitamineC", "carences_couvertes": ["vitamine_c", "vitamine_b9"], "portion_type": "1 bol (150g)"},
    {"id": "oranges", "nom": "Orange", "emoji": "🍊", "categorie": "fruitsVitamineC", "carences_couvertes": ["vitamine_c", "vitamine_b9"], "portion_type": "1 orange"},
    {"id": "bananes", "nom": "Banane", "emoji": "🍌", "categorie": "fruitsVitamineC", "carences_couvertes": ["vitamine_b6", "magnesium", "tryptophane"], "portion_type": "1 banane"},
    {"id": "yaourt", "nom": "Yaourt / Kéfir", "emoji": "🥛", "categorie": "produitsLaitiers", "carences_couvertes": ["calcium", "probiotiques", "vitamine_b2_b3", "zinc"], "portion_type": "1 pot (150g)"},
    {"id": "sardines_aretes", "nom": "Sardines entières (avec arêtes)", "emoji": "🐟", "categorie": "poissonsFruitsMer", "carences_couvertes": ["omega3", "vitamine_d", "vitamine_b12", "calcium"], "portion_type": "1 boîte (100g)"},
    {"id": "algues", "nom": "Algues (nori, wakamé, kombu)", "emoji": "🌿", "categorie": "autresAliments", "carences_couvertes": ["iode", "magnesium", "vitamine_b12"], "portion_type": "1 portion (10g)"},
    {"id": "foie_morue", "nom": "Huile de foie de morue", "emoji": "🧴", "categorie": "autresAliments", "carences_couvertes": ["vitamine_d", "omega3", "vitamine_a"], "portion_type": "1 cuillère à soupe"},
    {"id": "noix_bresil", "nom": "Noix du Brésil", "emoji": "🌰", "categorie": "oleagineuxGraines", "carences_couvertes": ["selenium", "magnesium", "zinc"], "portion_type": "2 noix (10g)"},
    {"id": "pommes_de_terre", "nom": "Pomme de terre (avec peau)", "emoji": "🥔", "categorie": "autresAliments", "carences_couvertes": ["vitamine_b6", "vitamine_c", "magnesium"], "portion_type": "2 pommes de terre (200g)"},
]

SYNERGIES = [
    {"id": "magnesium_vitamine_d", "type": "synergie", "nutriment_a": "magnesium", "nutriment_b": "vitamine_d", "force": "forte", "message": "Le magnésium est indispensable à l'activation de la vitamine D. Sans magnésium suffisant, la vitamine D supplémentée est peu efficace.", "source": "Zittermann et al. (2024, Eur J Nutrition) — RCT confirmé par 4 essais cliniques", "conseil_pratique": "Prendre magnésium et vitamine D ensemble, idéalement le soir avec un repas gras."},
    {"id": "vitamine_d_k2", "type": "synergie", "nutriment_a": "vitamine_d", "nutriment_b": "vitamine_k", "force": "forte", "message": "La vitamine K2 dirige le calcium (absorbé grâce à la vitamine D) vers les os plutôt que les artères. Essentielles ensemble.", "source": "van Ballegooijen et al. (Int J Endocrinology, 2017)", "conseil_pratique": "Toujours prendre D3 + K2 ensemble. Les formules combinées en gouttes sont idéales."},
    {"id": "vitamine_c_fer", "type": "synergie", "nutriment_a": "vitamine_c", "nutriment_b": "fer", "force": "forte", "message": "La vitamine C peut multiplier jusqu'à 9x l'absorption du fer non-héminique (végétal). Effet uniquement si pris au même repas.", "source": "ACS Omega (2022) — absorption passe de 0,8% à 7,1% selon la dose de vitamine C", "conseil_pratique": "Toujours accompagner les repas riches en fer végétal (lentilles, épinards) d'une source de vitamine C (citron, poivron, kiwi)."},
    {"id": "zinc_fer_antagonisme", "type": "antagonisme", "nutriment_a": "zinc", "nutriment_b": "fer", "force": "moderee", "message": "Le zinc et le fer entrent en compétition pour l'absorption intestinale. Les prendre ensemble réduit l'efficacité des deux.", "source": "Cambridge Nutrition Reviews (2000) + Sandstrom (2001)", "conseil_pratique": "Prendre zinc le matin avec le repas, fer en milieu d'après-midi. Minimum 2h d'écart."},
    {"id": "calcium_fer_antagonisme", "type": "antagonisme", "nutriment_a": "fer", "nutriment_b": "calcium", "force": "forte", "message": "Le calcium peut réduire l'absorption du fer non-héminique jusqu'à 60%. Ne jamais prendre un complément de calcium au même repas qu'un complément de fer.", "source": "Drugs.com Medical Review (2025), BuzzRx (2025)", "conseil_pratique": "Calcium le soir (avec la vitamine D), fer à midi loin des produits laitiers."},
    {"id": "omega3_vitamine_d_synergie", "type": "synergie", "nutriment_a": "omega3", "nutriment_b": "vitamine_d", "force": "moderee", "message": "Les oméga-3 améliorent l'absorption de la vitamine D (liposoluble) et potentialisent ses effets anti-inflammatoires.", "source": "Interactions of Vitamin D, Magnesium, Zinc, K2, Boron — Nutrients Review (2025)", "conseil_pratique": "Prendre vitamine D et oméga-3 ensemble avec un repas gras pour maximiser leur absorption."},
    {"id": "microbiote_absorption_generale", "type": "synergie", "nutriment_a": "probiotiques", "nutriment_b": "tous", "force": "forte", "message": "Un microbiote équilibré améliore l'absorption de la quasi-totalité des vitamines et minéraux. Un intestin dysbiotique rend toute supplémentation moins efficace.", "source": "Barone et al. (BioFactors, 2022) — revue clinique complète", "conseil_pratique": "Rétablir le microbiote en priorité si troubles digestifs : toutes les autres supplémentations seront plus efficaces ensuite."},
    {"id": "vitamine_a_fer_synergie", "type": "synergie", "nutriment_a": "vitamine_a", "nutriment_b": "fer", "force": "moderee", "message": "La vitamine A et le bêta-carotène améliorent l'absorption du fer non-héminique et participent à la mobilisation des réserves de fer.", "source": "Sandstrom (British Journal of Nutrition, 2001)", "conseil_pratique": "Inclure des carottes ou patates douces (bêta-carotène) dans les repas riches en fer végétal."},
    {"id": "zinc_vitamine_a_cofacteur", "type": "synergie", "nutriment_a": "zinc", "nutriment_b": "vitamine_a", "force": "moderee", "message": "Le zinc est nécessaire au transport et au métabolisme de la vitamine A dans l'organisme. Une carence en zinc peut induire une carence fonctionnelle en vitamine A même si les réserves sont normales.", "source": "Smith et al. (Science, 1973) — confirmé par Nutrient Synergy PMC (2023)", "conseil_pratique": "Corriger le zinc en même temps que la vitamine A pour une efficacité maximale des deux."},
    {"id": "magnesium_zinc_antagonisme_doses_elevees", "type": "antagonisme", "nutriment_a": "magnesium", "nutriment_b": "zinc", "force": "faible", "message": "À doses élevées (supplément), magnésium et zinc partagent des voies d'absorption et peuvent se concurrencer légèrement. Aux doses normales, pas d'interaction significative.", "source": "Drugs.com Medical Review (2025)", "conseil_pratique": "Aux doses recommandées (Mg 300mg, Zinc 15mg), aucun problème. Éviter de dépasser les doses sans avis médical."},
]

HORAIRES = [
    {"complement_id": "vitamine_d3_k2", "moment": "Repas du midi ou du soir", "avec": "Repas contenant des graisses (huile, poisson, avocat)", "eviter": "À jeun — absorption réduite de 50% sans graisses", "priorite": 1},
    {"complement_id": "magnesium", "moment": "Le soir, 1h avant le coucher", "avec": "Seul ou avec un petit repas léger", "eviter": "Le matin (effet relaxant) ; loin du calcium (compétition légère)", "priorite": 2},
    {"complement_id": "zinc", "moment": "Le matin avec le petit-déjeuner", "avec": "Avec un repas protéiné", "eviter": "À jeun (nausées) ; au même repas que le fer ; loin des produits laitiers riches en calcium", "priorite": 3},
    {"complement_id": "vitamine_c", "moment": "Le matin à jeun ou avec les repas riches en fer", "avec": "Eau ou jus, idéalement avec lentilles/épinards pour l'absorption du fer", "eviter": "Avec de très hautes doses de B12 (peut réduire légèrement la B12)", "priorite": 4},
    {"complement_id": "omega3", "moment": "Repas du matin ou du midi", "avec": "Repas gras pour maximiser l'absorption", "eviter": "Le soir pour certaines personnes (peut perturber le sommeil)", "priorite": 5},
    {"complement_id": "complexe_b", "moment": "Le matin avec le petit-déjeuner", "avec": "Repas pour éviter les nausées", "eviter": "Le soir (effet stimulant sur le système nerveux)", "priorite": 6},
    {"complement_id": "vitamine_b12", "moment": "Le matin à jeun ou sous la langue", "avec": "Seule (meilleure absorption) ou sublingual", "eviter": "Avec de la vitamine C en très haute dose", "priorite": 7},
    {"complement_id": "fer", "moment": "Milieu d'après-midi (entre midi et dîner)", "avec": "Vitamine C (jus d'orange ou comprimé) pour booster l'absorption", "eviter": "Calcium (produits laitiers), zinc, café, thé — réduisent tous l'absorption du fer", "priorite": 8},
    {"complement_id": "probiotiques", "moment": "Le matin à jeun", "avec": "Eau froide uniquement", "eviter": "Eau chaude ou bouillante (tue les bactéries) ; antibiotiques (prendre à 2h d'écart minimum)", "priorite": 9},
]


def write_json(path: Path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    write_json(RES / "aliments_trackables.json", ALIMENTS)
    write_json(RES / "synergies_nutriments.json", SYNERGIES)
    write_json(RES / "horaires_prise.json", HORAIRES)

    supp_path = RES / "recettes_supplementaires.json"
    if not supp_path.exists():
        raise SystemExit(f"Missing {supp_path}")

    with supp_path.open(encoding="utf-8") as f:
        supp = json.load(f)

    with (RES / "recettes_base.json").open(encoding="utf-8") as f:
        base = json.load(f)

    base["recettes"].extend(supp["recettes_supplementaires"])
    base["version"] = "2.0.0"
    base["total_recettes"] = len(base["recettes"])
    write_json(RES / "recettes_v2.json", base)
    print(f"OK: {len(ALIMENTS)} aliments, {len(SYNERGIES)} synergies, {len(HORAIRES)} horaires, {len(base['recettes'])} recettes")


if __name__ == "__main__":
    main()
