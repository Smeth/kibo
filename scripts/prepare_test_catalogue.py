"""Prepare des donnees fictives et telecharge leurs images, sans acces Supabase."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "test_catalogue"
BATCH = "kibo-demo-20261102-v1"
CATEGORIES = [
    ("Téléphones et informatique", ["smartphones", "laptops", "tablets"], "Téléphone ou ordinateur", 45000),
    ("Véhicules et motos", ["vehicle", "motorcycle"], "Véhicule ou moto", 450000),
    ("Immobilier", ["furniture", "home-decoration"], "Logement meublé, photo illustrative", 85000),
    ("Maison et équipement", ["kitchen-accessories", "furniture"], "Équipement pour la maison", 12000),
    ("Mode et beauté", ["beauty", "fragrances", "womens-bags", "mens-shirts"], "Mode et soin personnel", 7500),
    ("Services", ["mobile-accessories", "laptops"], "Assistance et entretien informatique", 15000),
    ("Alimentation", ["groceries"], "Produit alimentaire", 1500),
    ("Emploi et formation", ["laptops", "tablets"], "Atelier de formation bureautique", 20000),
    ("Loisirs et divertissement", ["sports-accessories"], "Accessoire de sport et loisir", 18000),
]
CITIES = ["Brazzaville"] * 6 + ["Pointe-Noire"] * 2 + ["Dolisie", "Nkayi", "Ouesso", "Owando"]
QUESTIONS = [
    "Bonjour, cette annonce est-elle encore disponible ?",
    "Peut-on avoir davantage de précisions sur l’état et les caractéristiques ?",
    "Le prix indiqué est-il négociable ?",
    "Dans quel quartier peut-on en discuter ?",
    "Est-ce possible de convenir d’un rendez-vous cette semaine ?",
    "Merci pour les détails. Pouvez-vous préciser les conditions proposées ?",
]
ANSWERS = [
    "Oui, cet échange fait partie de la simulation. Aucune vente réelle n’est proposée.",
    "Bien reçu. Cette réponse fictive permet de tester la discussion et ses notifications.",
    "Nous pouvons en discuter dans ce scénario de test, sans engagement réel.",
]

def ident(kind, number):
    value = uuid.uuid5(uuid.NAMESPACE_URL, f"https://kibo.invalid/{BATCH}/{kind}/{number}")
    # Le parcours createOnce accepte la forme UUID v4. Pour les fixtures,
    # conserver une empreinte déterministe en positionnant les bits requis.
    return str(uuid.UUID(bytes=value.bytes, version=4)) if kind == "listing" else str(value)

def prepare(products):
    rows, used = [], set()
    for category, sources, label, price in CATEGORIES:
        pool = [p for p in products if p["category"] in sources]
        if not pool:
            raise ValueError(f"Pas de source pour {category}")
        for local in range(12):
            number = len(rows) + 1
            candidates = [p for p in pool if p["id"] not in used]
            product = candidates[0] if candidates else pool[local % len(pool)]
            used.add(product["id"])
            city = CITIES[local]
            title = f"[TEST {number:03}] {label}"
            if category not in ("Immobilier", "Services", "Emploi et formation"):
                title += f" — {product['title']}"
            title = title[:120]
            description = (
                f"DONNÉE FICTIVE — lot {BATCH}, annonce {number:03}. "
                "Aucun produit ni service réellement proposé à la vente. "
                f"Scénario à {city}, catégorie {category}. "
                f"Prix de test en XAF : {price + local * (price // 5 + 500)}. "
                "Image illustrative de catalogue utilisée pour tester les cartes, le détail, "
                "la recherche, les filtres, les favoris et les échanges. "
                "Ne pas organiser d’achat ou de rendez-vous pour cette annonce."
            )
            listing_id = ident("listing", number)
            comments = []
            for q in range(2):
                root_id = ident("comment", f"{number}-{q}-question")
                for role, parent, suffix, body in [
                    ("buyer", None, "question", QUESTIONS[(number + q) % len(QUESTIONS)]),
                    ("seller", root_id, "reply", ANSWERS[(number + q) % len(ANSWERS)]),
                ]:
                    comments.append({"id": ident("comment", f"{number}-{q}-{suffix}"),
                        "author_role": role, "parent_id": parent,
                        "content": f"[TEST {number:03}/{q + 1}] {body}"})
            rows.append({"id": listing_id, "title": title, "description": description,
                "price": str(price + local * (price // 5 + 500)), "city": city,
                "neighborhood": "Zone fictive de recette", "category": category,
                "listing_type": "service" if category in ("Services", "Emploi et formation") else "product",
                "image_asset": f"assets/test_catalogue/images/{number:03}.webp",
                "image_source": product["thumbnail"], "source_product_id": product["id"],
                "comments": comments})
    return {"batch": BATCH, "fixture": True, "currency": "XAF", "country": "CG", "listings": rows}

def download(row):
    url = row["image_source"]
    if not url.startswith("https://cdn.dummyjson.com/"):
        raise ValueError("Hôte image non autorisé")
    target = ROOT / row["image_asset"]
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(4 * 1024 * 1024 + 1)
        if not data or len(data) > 4 * 1024 * 1024:
            raise ValueError("Taille image invalide")
        target.write_bytes(data)
    return row["image_asset"], hashlib.sha256(target.read_bytes()).hexdigest()

if __name__ == "__main__":
    source = ROOT / ".dart_tool" / "demo-preparation" / "products.json"
    dataset = prepare(json.loads(source.read_text(encoding="utf-8-sig"))["products"])
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        hashes = dict(pool.map(download, dataset["listings"]))
    for row in dataset["listings"]:
        row["image_sha256"] = hashes[row["image_asset"]]
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "catalogue.json").write_text(json.dumps(dataset, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(dataset['listings'])} annonces, {sum(len(r['comments']) for r in dataset['listings'])} commentaires/reponses, {len(hashes)} fichiers image prepares.")
