#!/usr/bin/env python3
"""Collect Bangla agriculture headlines into assets/data/briefing.json.

Runs every few hours in GitHub Actions (.github/workflows/briefing.yml).
Only titles, source names, times and links are stored; the app opens the
original article in the browser. Edit SOURCES to change topics.
If nothing can be fetched, the old file is left untouched.
"""
import email.utils
import json
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "data" / "briefing.json"

# (topic shown in the app, search words)
SOURCES = [
    ("কৃষি", "কৃষি কৃষক ফসল"),
    ("মাছ", "মাছ চাষ মৎস্য"),
    ("বাজার", "বাজার দর চাল সবজি"),
    ("আবহাওয়া", "আবহাওয়া সতর্কতা বৃষ্টি"),
]
# A headline must contain one of its topic's words (drops off-topic news).
KEYWORDS = {
    "কৃষি": ["কৃষি", "কৃষক", "ফসল", "ধান", "চাষ", "সার", "বীজ", "সবজি", "আলু", "গম", "পাট"],
    "মাছ": ["মাছ", "মৎস্য", "চিংড়ি", "পুকুর", "জেলে", "ইলিশ", "পোনা"],
    "বাজার": ["দাম", "দর", "বাজার", "চাল", "সবজি", "মাছ", "পেঁয়াজ", "আলু", "ডিম"],
    "আবহাওয়া": ["আবহাওয়া", "বৃষ্টি", "ঝড়", "ঘূর্ণিঝড়", "শীত", "তাপ", "বন্যা", "সংকেত", "কুয়াশা"],
}
# Bangla-language outlets/places from outside Bangladesh.
# (Only names that are not ordinary Bangla words.)
NOT_BD = [
    "ABP", "Anandabazar", "আনন্দবাজার", "Asianet", "Zee 24", "News18", "TV9", "Ei Samay",
    "Sangbad Pratidin", "Bartaman", "Hindustan Times", "Aajkaal", "Kolkata", "কলকাতা",
    "পশ্চিমবঙ্গ", "West Bengal", "India Today",
]
PER_TOPIC = 6
MAX_ITEMS = 20
MAX_AGE = timedelta(days=4)


def feed_url(words: str) -> str:
    q = urllib.parse.quote(f"{words} when:4d")
    return f"https://news.google.com/rss/search?q={q}&hl=bn&gl=BD&ceid=BD:bn"


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "Chashibondhu-briefing/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read()


def parse(xml: bytes, topic: str):
    root = ET.fromstring(xml)
    now = datetime.now(timezone.utc)
    for item in root.iter("item"):
        title = (item.findtext("title") or "").strip()
        link = (item.findtext("link") or "").strip()
        source = (item.findtext("source") or "").strip()
        pub = item.findtext("pubDate")
        if not title or not link.startswith("https://"):
            continue
        # Google adds " - Source" at the end of the title.
        if source and title.endswith(f" - {source}"):
            title = title[: -len(source) - 3].strip()
        when = None
        if pub:
            try:
                when = email.utils.parsedate_to_datetime(pub).astimezone(timezone.utc)
            except (TypeError, ValueError):
                when = None
        if when and now - when > MAX_AGE:
            continue
        text = f"{title} {source}"
        if any(x.lower() in text.lower() for x in NOT_BD):
            continue
        if not any(k in title for k in KEYWORDS.get(topic, [])):
            continue
        yield {
            "title": title,
            "source": source,
            "url": link,
            "published": when.isoformat() if when else None,
            "topic": topic,
        }


def main() -> int:
    items, seen = [], set()
    for topic, words in SOURCES:
        try:
            got = list(parse(fetch(feed_url(words)), topic))
        except Exception as e:  # network or format problem: skip this topic
            print(f"skip {topic}: {e}", file=sys.stderr)
            continue
        got.sort(key=lambda x: x["published"] or "", reverse=True)
        n = 0
        for it in got:
            key = it["title"][:60]
            if key in seen:
                continue
            seen.add(key)
            items.append(it)
            n += 1
            if n >= PER_TOPIC:
                break
    if not items:
        print("nothing fetched; keeping old file")
        return 0
    items.sort(key=lambda x: x["published"] or "", reverse=True)
    data = {
        "version": 1,
        "updated": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "items": items[:MAX_ITEMS],
    }
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {len(data['items'])} headlines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
