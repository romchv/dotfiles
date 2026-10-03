#!/usr/bin/env python3
"""Builds emoji.tsv for the emoji picker: one emoji per line, then its name
and CLDR keywords, tab separated, in Unicode's order. Skin tone and hair
variants are left out. Run from this directory:

    curl -O https://unicode.org/Public/emoji/16.0/emoji-test.txt
    curl -LO https://raw.githubusercontent.com/unicode-org/cldr/main/common/annotations/en.xml
    ./make-emoji.py emoji-test.txt en.xml > emoji.tsv

Keep the Emoji version at or below what noto-fonts-emoji can draw.
"""
import re
import sys
import xml.etree.ElementTree as ET

test, annotations = sys.argv[1:3]

keywords = {}
for a in ET.parse(annotations).getroot().iter("annotation"):
    if a.get("type") != "tts":
        keywords[a.get("cp")] = [k.strip() for k in a.text.split("|")]

modifiers = re.compile("[\U0001F3FB-\U0001F3FF\U0001F9B0-\U0001F9B3]")
for line in open(test, encoding="utf-8"):
    m = re.match(r"^[0-9A-F ]+;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.+)$", line)
    if not m:
        continue
    emoji, name = m.groups()
    if modifiers.search(emoji):
        continue
    words = [k for k in keywords.get(emoji, keywords.get(emoji.replace("️", ""), [])) if k != name]
    print(f"{emoji}\t{name}\t{' | '.join(words)}")
