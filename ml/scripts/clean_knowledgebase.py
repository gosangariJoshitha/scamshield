import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
KNOWLEDGE_PATH = ROOT / "ml" / "data" / "raw" / "knowledge_base.json"
sys.path.insert(0, str(ROOT))

from ml.scripts.knowledge_base_source import load_knowledge_records


def main() -> None:
    data, records = load_knowledge_records(KNOWLEDGE_PATH)
    print(f"Validated canonical knowledge base v{data.get('version')}.")
    print(f"Total knowledge articles: {len(data['articles'])}")
    print(
        "External guidance sources: "
        f"{sum(record['source_type'] == 'EXTERNAL_GUIDANCE' for record in records)}"
    )
    print(f"Localized records ready for indexing: {len(records) * 3}")


if __name__ == "__main__":
    main()
