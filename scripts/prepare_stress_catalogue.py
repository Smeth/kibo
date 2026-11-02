"""Lot de charge borne : 1080 annonces, sans acces Supabase ni nouveaux contacts."""
import json
from pathlib import Path
import re
import uuid

ROOT = Path(__file__).resolve().parents[1]
BATCH = "kibo-stress-20261102-v1"

def identifier(kind, value):
    result = uuid.uuid5(uuid.NAMESPACE_URL, f"https://kibo.invalid/{BATCH}/{kind}/{value}")
    return str(uuid.UUID(bytes=result.bytes, version=4)) if kind == "listing" else str(result)

def generate(source):
    rows = []
    for repeat in range(10):
        for original in source["listings"]:
            number = len(rows) + 1
            row = dict(original)
            row["id"] = identifier("listing", number)
            row["title"] = (f"[TEST PERF {number:04}] " + re.sub(r"^\[TEST \d+\] ", "", original["title"]))[:120]
            row["description"] = (
                f"DONNÉE FICTIVE DE PERFORMANCE — lot {BATCH}, annonce {number:04}. "
                "Aucun produit ni service réellement proposé. "
                f"Scénario à {row['city']}, catégorie {row['category']}, prix {row['price']} XAF. "
                "Image illustrative réutilisée depuis le premier jeu de fixtures. "
                "Cette annonce teste la pagination, le cache, la recherche et les actions de gestion. "
                "Ne pas organiser de transaction pour ce contenu de test."
            )
            mapping = {c["id"]: identifier("comment", f"{number}-{i}") for i, c in enumerate(original["comments"])}
            row["comments"] = [dict(c, id=mapping[c["id"]],
                parent_id=mapping[c["parent_id"]] if c["parent_id"] else None,
                content=f"[TEST PERF {number:04}/{i + 1}] " + re.sub(r"^\[TEST \d+/\d+\] ", "", c["content"]))
                for i, c in enumerate(original["comments"])]
            rows.append(row)
    return dict(source, batch=BATCH, listings=rows)

if __name__ == "__main__":
    source = json.loads((ROOT / "assets/test_catalogue/catalogue.json").read_text(encoding="utf-8"))
    result = generate(source)
    (ROOT / "assets/test_catalogue/stress_catalogue.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(result['listings'])} annonces, {sum(len(r['comments']) for r in result['listings'])} commentaires/reponses ; 108 images sources reutilisees.")
