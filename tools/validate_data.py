#!/usr/bin/env python3
"""Validates every JSON/text asset used by the app. Run: python tools/validate_data.py"""
import json, os, re, sys

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data')
errors = []

def err(msg):
    errors.append(msg)

# vocab
seen = set()
n = 0
with open(os.path.join(root, 'vocab.txt'), encoding='utf-8') as f:
    for ln, line in enumerate(f, 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split('|')
        if len(parts) != 3 or not all(p.strip() for p in parts):
            err(f'vocab.txt line {ln}: expected 3 non-empty fields: {line!r}')
            continue
        if parts[0] in seen:
            err(f'vocab.txt line {ln}: duplicate {parts[0]!r}')
        seen.add(parts[0])
        n += 1
print(f'vocab: {n} words')

def check_question(where, q):
    t = q.get('t')
    if t not in ('mc', 'fill', 'order'):
        err(f'{where}: bad type {t!r}'); return
    if not q.get('q'):
        err(f'{where}: missing q')
    if t == 'mc':
        o, a = q.get('o'), q.get('a')
        if not isinstance(o, list) or len(o) < 2 or not isinstance(a, int) or not (0 <= a < len(o)):
            err(f'{where}: bad mc options/answer')
    else:
        a = q.get('a')
        if not isinstance(a, list) or not a or not all(isinstance(x, str) and x.strip() for x in a):
            err(f'{where}: bad answers')
        elif t == 'order':
            base = sorted(re.sub(r'[.,!?;:]', '', w).lower() for w in a[0].split())
            for alt in a[1:]:
                if sorted(re.sub(r'[.,!?;:]', '', w).lower() for w in alt.split()) != base:
                    err(f'{where}: alternative {alt!r} cannot be built from the chips of {a[0]!r}')

total_q = 0
lessons_dir = os.path.join(root, 'lessons')
for day in range(1, 15):
    p = os.path.join(lessons_dir, f'day{day:02d}.json')
    try:
        d = json.load(open(p, encoding='utf-8'))
    except Exception as e:
        err(f'{p}: {e}'); continue
    if d.get('day') != day:
        err(f'day{day:02d}: day field mismatch')
    for i, q in enumerate(d.get('questions', [])):
        check_question(f'day{day:02d} q{i+1}', q)
    total_q += len(d.get('questions', []))
print(f'lessons: 14 days, {total_q} questions')

# mocks
mocks = json.load(open(os.path.join(root, 'mocks.json'), encoding='utf-8'))['mocks']
for m in mocks:
    for s in m['sections']:
        count = 0
        for part in s['parts']:
            for c in part['clips']:
                if not (c.get('text') or c.get('audio')):
                    err(f"{m['id']}/{s['id']}: clip without text/audio")
                for it in c['items']:
                    count += 1
                    if 'r' in it:
                        if not isinstance(it['r'], bool): err(f"{m['id']}/{s['id']}: bad r")
                    else:
                        o, a = it.get('o'), it.get('a')
                        if not isinstance(o, list) or not isinstance(a, int) or not (0 <= a < len(o)):
                            err(f"{m['id']}/{s['id']}: bad item {it.get('q')!r}")
        print(f"mock {m['id']} {s['id']}: {count} items")

# writing + speaking
w = json.load(open(os.path.join(root, 'writing.json'), encoding='utf-8'))
for k in ('forms', 'prompts', 'examples', 'frames', 'phrases', 'checklist'):
    if not w.get(k): err(f'writing.json: missing {k}')
s = json.load(open(os.path.join(root, 'speaking.json'), encoding='utf-8'))
for k in ('teil1', 'teil2', 'teil3', 'pron'):
    if not s.get(k): err(f'speaking.json: missing {k}')
tpl = s['teil1']['template']
for f in s['teil1']['fields']:
    if '{' + f['k'] + '}' not in tpl: err(f"speaking.json: template misses {f['k']}")
print(f"writing: {len(w['prompts'])} prompts, speaking: {len(s['teil2'])}+{len(s['teil3'])} cards")

if errors:
    print('\nERRORS:'); [print(' -', e) for e in errors]; sys.exit(1)
print('\nAll data OK')
