#!/usr/bin/env python3
"""
BAĞDAT için gerçek kitap veri setlerini birleştirip Modül 2 (Katalog) tablolarına yükler.

Kullanım:
  python bagdat_gercek_katalog_yukle.py --schema bagdat_schema.sql --out bagdat_gercek.db \
      goodreads_books.csv 7k_books.csv [diger.csv ...]

Dosyaların SIRASI önceliktir: ilk dosyadaki dolu değer korunur, boş kalan hücreler sonraki dosyalardan doldurulur.
Ortak anahtar ISBN-13'tür (ISBN-10 verilmişse 13'e çevrilir). ISBN'i olmayan satırlar "başlık + ilk yazar" ile eşleştirilir.
Sütun adları dosyadan dosyaya değişirse aşağıdaki SYNONYMS sözlüğüne yeni ad ekleyin.
"""
import argparse, collections, datetime as dt, random, re, sqlite3, sys, unicodedata
import pandas as pd

SYNONYMS = {
    "isbn13": ["isbn13", "isbn_13", "isbn-13", "isbn 13"],
    "isbn10": ["isbn10", "isbn_10", "isbn-10", "isbn 10", "isbn"],
    "title": ["title", "book title", "book-title", "name"],
    "subtitle": ["subtitle"],
    "authors": ["authors", "author", "book author", "creator"],
    "publisher": ["publisher"],
    "categories": ["categories", "category", "genre", "subjects"],
    "year": ["published_year", "year of publication", "publicationyear", "publication_year", "release year", "released year"],
    "date": ["publication_date", "published date", "publication-date", "publishdate"],
    "pages": ["num_pages", "page count", "pages", "number_of_pages", "pagecount"],
    "lang": ["language_code", "language", "lang"],
    "description": ["description", "synopsis"],
}
LANG = {"eng": "İngilizce", "en": "İngilizce", "en-us": "İngilizce", "en-gb": "İngilizce", "en-ca": "İngilizce", "english": "İngilizce",
        "spa": "İspanyolca", "es": "İspanyolca", "fre": "Fransızca", "fra": "Fransızca", "fr": "Fransızca", "ger": "Almanca", "de": "Almanca",
        "tur": "Türkçe", "tr": "Türkçe", "turkish": "Türkçe", "ita": "İtalyanca", "it": "İtalyanca", "jpn": "Japonca", "ja": "Japonca",
        "por": "Portekizce", "pt": "Portekizce", "rus": "Rusça", "ru": "Rusça"}
THIS_YEAR = dt.date.today().year


# ---------- ISBN yardımcıları ----------
def clean_isbn(x):
    if x is None or (isinstance(x, float) and pd.isna(x)):
        return None
    s = re.sub(r"[^0-9Xx]", "", str(x)).upper()
    return s or None


def isbn10_ok(s):
    if not s or len(s) != 10 or not re.fullmatch(r"\d{9}[\dX]", s):
        return False
    total = sum((10 - i) * (10 if c == "X" else int(c)) for i, c in enumerate(s))
    return total % 11 == 0


def isbn13_ok(s):
    if not s or len(s) != 13 or not s.isdigit():
        return False
    return sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(s)) % 10 == 0


def isbn10_to_13(s):
    core = "978" + s[:9]
    chk = (10 - sum(int(c) * (1 if i % 2 == 0 else 3) for i, c in enumerate(core)) % 10) % 10
    return core + str(chk)


def best_isbn13(i13, i10):
    i13, i10 = clean_isbn(i13), clean_isbn(i10)
    if i13 and isbn13_ok(i13):
        return i13
    if i10 and isbn10_ok(i10):
        return isbn10_to_13(i10)
    if i10 and isbn13_ok(i10):       # bazı dosyalarda 'isbn' sütununda 13 haneli değer olur
        return i10
    return None


def norm(s):
    s = unicodedata.normalize("NFKD", str(s or "").lower())
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


# ---------- Okuma ve ortak biçime çevirme ----------
def read_source(path):
    bad = []
    for enc in ("utf-8-sig", "latin-1"):
        try:
            df = pd.read_csv(path, dtype=str, encoding=enc, engine="python", on_bad_lines=lambda row: bad.append(row) or None)
            break
        except UnicodeDecodeError:
            continue
    cols = {c.strip().lower(): c for c in df.columns}
    out = pd.DataFrame(index=df.index)
    for canon, names in SYNONYMS.items():
        used = next((cols[n] for n in names if n in cols), None)
        out[canon] = df[used].astype("string").str.strip() if used else pd.NA
    out = out.replace("", pd.NA)
    # yıl: yıl sütunu yoksa tarihten 4 haneli yılı al
    yr = out["year"].where(out["year"].notna(), out["date"].str.extract(r"((?:1[4-9]|20)\d\d)", expand=False))
    out["year"] = pd.to_numeric(yr.str.extract(r"((?:1[4-9]|20)\d\d)", expand=False), errors="coerce")
    out["pages"] = pd.to_numeric(out["pages"], errors="coerce")
    out = out.drop(columns=["date"])
    out["isbn13"] = [best_isbn13(a, b) for a, b in zip(out["isbn13"], out["isbn10"])]
    out = out.drop(columns=["isbn10"])
    first_author = out["authors"].fillna("").str.split(r"[/;]").str[0].map(norm)
    out["key"] = [i if i else ("T:" + norm(t) + "|" + a) for i, t, a in zip(out["isbn13"], out["title"].fillna(""), first_author)]
    out = out[out["title"].notna()]
    stats = dict(rows=len(df), bad_lines=len(bad), no_isbn=int(out["isbn13"].isna().sum()))
    # aynı anahtar tekrar ediyorsa en dolu satırı tut
    out["_filled"] = out.notna().sum(axis=1)
    before = len(out)
    out = out.sort_values("_filled", ascending=False, kind="stable").drop_duplicates("key").drop(columns="_filled")
    stats["duplicates"] = before - len(out)
    return out.set_index("key"), stats


def merge_sources(paths):
    merged, report = None, []
    for p in paths:
        df, st = read_source(p)
        st["file"] = p
        if merged is None:
            merged = df
            st.update(common=0, new=len(df), filled={})
        else:
            common = merged.index.intersection(df.index)
            filled = {}
            for c in merged.columns:
                n = int((merged.loc[common, c].isna() & df.loc[common, c].notna()).sum())
                if n:
                    filled[c] = n
            st.update(common=len(common), new=len(df.index.difference(merged.index)), filled=filled)
            merged = merged.combine_first(df)
        report.append(st)
    return merged.reset_index(drop=True), report


# ---------- Ayrıştırma: yazar, kategori, dil ----------
ROLE = {"translator": "Çevirmen", "editor": "Editör", "illustrator": None, "introduction": None, "foreword": None, "afterword": None}


def split_authors(s):
    if s is None or pd.isna(s):
        return []
    out = []
    for part in re.split(r"[/;]", str(s)):
        part = part.strip()
        if not part:
            continue
        m = re.search(r"\(([^)]*)\)\s*$", part)
        role = "Yazar"
        if m:
            role = ROLE.get(m.group(1).strip().lower(), "Yazar")
            part = part[: m.start()].strip()
        if role is None or not part:
            continue
        out.append((part, role))
    return out


def split_name(full):
    toks = full.replace(",", " ").split()
    if len(toks) == 1:
        return "-", toks[0]
    return " ".join(toks[:-1]), toks[-1]


def first_category(s):
    if s is None or pd.isna(s):
        return None
    return re.split(r"[/;]", str(s))[0].strip() or None


# ---------- Yükleme ----------
def load_to_db(df, schema_path, out_db, drop_incomplete, kmin, kmax, seed=7):
    random.seed(seed)
    import os
    if os.path.exists(out_db):
        os.remove(out_db)
    con = sqlite3.connect(out_db)
    con.execute("PRAGMA foreign_keys=ON")
    con.executescript(open(schema_path, encoding="utf-8").read())
    cur = con.cursor()

    def ins(table, **kw):
        cur.execute(f"INSERT INTO {table} ({','.join(kw)}) VALUES ({','.join('?' * len(kw))})", list(kw.values()))
        return cur.lastrowid

    # Kopya için gereken şube ve raflar (gerçek veri kaynağında bulunmaz, örnek kurulur)
    subeler = [ins("Subeler", sube_adi=n, sehir="Malatya") for n in ("Merkez Kütüphane", "Fen Fakültesi Şubesi", "Mühendislik Şubesi")]
    raflar = {s: [ins("Raflar", sube_id=s, raf_kodu=f"R-{s}-{k:02d}", kapasite=200) for k in range(1, 7)] for s in subeler}
    pub_id, cat_id, auth_id = {}, {}, {}
    dropped, placeholder = 0, collections.Counter()
    n_books = n_copies = 0
    for r in df.itertuples(index=False):
        pub = r.publisher if pd.notna(r.publisher) else None
        cat = first_category(r.categories)
        if drop_incomplete and (pub is None or cat is None):
            dropped += 1
            continue
        if pub is None:
            pub, _ = "Bilinmeyen Yayınevi", placeholder.update(["yayınevi"])
        if cat is None:
            cat, _ = "Sınıflandırılmamış", placeholder.update(["kategori"])
        if pub not in pub_id:
            pub_id[pub] = ins("Yayinevleri", yayinevi_adi=pub)
        if cat not in cat_id:
            cat_id[cat] = ins("Kategoriler", ust_kategori_id=None, kategori_adi=cat)
        title = str(r.title)
        if pd.notna(r.subtitle) and norm(r.subtitle) not in norm(title):
            title = f"{title}: {r.subtitle}"
        year = int(r.year) if pd.notna(r.year) and 1450 <= r.year <= THIS_YEAR else None
        pages = int(r.pages) if pd.notna(r.pages) and r.pages > 0 else None
        lang = LANG.get(str(r.lang).strip().lower(), str(r.lang).strip()) if pd.notna(r.lang) else None
        kid = ins("Kitaplar", yayinevi_id=pub_id[pub], kategori_id=cat_id[cat], kitap_adi=title[:250], isbn=r.isbn13 if pd.notna(r.isbn13) else None,
                  basim_yili=year, sayfa_sayisi=pages, dil=lang[:30] if lang else None, ozet=str(r.description) if pd.notna(r.description) else None)
        n_books += 1
        seen = set()
        order = 0
        for name, role in split_authors(r.authors) or [("Bilinmeyen Yazar", "Yazar")]:
            ad, soyad = split_name(name)
            k = (norm(ad), norm(soyad))
            if k in seen:
                continue
            seen.add(k)
            if k not in auth_id:
                auth_id[k] = ins("Yazarlar", ad=ad[:50], soyad=soyad[:50])
            order += 1
            ins("Kitap_Yazar", kitap_id=kid, yazar_id=auth_id[k], yazar_sirasi=order, katki_turu=role)
        for _ in range(random.randint(kmin, kmax)):
            n_copies += 1
            s = random.choice(subeler)
            ins("Kitap_Kopyalari", kitap_id=kid, sube_id=s, raf_id=random.choice(raflar[s]), barkod=f"KPY-{n_copies:06d}",
                edinme_turu=random.choice(["Satın Alma", "Bağış"]), edinme_tarihi=(dt.date(2015, 1, 1) + dt.timedelta(random.randint(0, 3800))).isoformat(),
                fiyat=round(random.uniform(40, 400), 2))
    con.commit()
    fk = con.execute("PRAGMA foreign_key_check").fetchall()
    counts = {t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in ("Yayinevleri", "Kategoriler", "Yazarlar", "Kitaplar", "Kitap_Yazar", "Kitap_Kopyalari")}
    return con, counts, dict(dropped=dropped, placeholder=dict(placeholder), fk_errors=len(fk))


def dump_sql(con, path, tables):
    def lit(v):
        return "NULL" if v is None else ("'" + v.replace("'", "''") + "'" if isinstance(v, str) else repr(v))
    with open(path, "w", encoding="utf-8") as f:
        f.write("PRAGMA foreign_keys=ON;\nBEGIN TRANSACTION;\n")
        for t in tables:
            cols = [r[1] for r in con.execute(f"PRAGMA table_info({t})")]
            for row in con.execute(f"SELECT * FROM {t} ORDER BY rowid"):
                f.write(f"INSERT INTO {t} ({', '.join(cols)}) VALUES ({', '.join(lit(v) for v in row)});\n")
        f.write("COMMIT;\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sources", nargs="+", help="CSV dosyaları (öncelik sırasıyla)")
    ap.add_argument("--schema", default="bagdat_schema.sql")
    ap.add_argument("--out", default="bagdat_gercek.db")
    ap.add_argument("--sql", default="bagdat_gercek_katalog.sql", help="INSERT dosyası")
    ap.add_argument("--max-books", type=int, default=0, help="0 = hepsi; ders projesi için 1000-3000 yeterli")
    ap.add_argument("--drop-incomplete", action="store_true", help="yayınevi ya da kategorisi olmayan kitapları at (varsayılan: 'Bilinmeyen' ile doldur)")
    ap.add_argument("--kopya-min", type=int, default=1)
    ap.add_argument("--kopya-max", type=int, default=3)
    a = ap.parse_args()
    df, rep = merge_sources(a.sources)
    print("== Kaynak raporu")
    for r in rep:
        print(f"{r['file']}: {r['rows']} satır, bozuk satır {r['bad_lines']}, ISBN'siz {r['no_isbn']}, tekrar eden {r['duplicates']}, "
              f"ortak {r['common']}, yeni {r['new']}, doldurulan boşluklar {r['filled']}")
    print(f"Birleşik kayıt sayısı: {len(df)}")
    if a.max_books and len(df) > a.max_books:
        df = df.sample(a.max_books, random_state=1).reset_index(drop=True)
        print(f"Örneklem: {a.max_books} kitap")
    con, counts, info = load_to_db(df, a.schema, a.out, a.drop_incomplete, a.kopya_min, a.kopya_max)
    print("== Yüklenen satırlar:", counts)
    print("== Notlar:", info)
    dump_sql(con, a.sql, ["Subeler", "Raflar", "Yayinevleri", "Kategoriler", "Yazarlar", "Kitaplar", "Kitap_Yazar", "Kitap_Kopyalari"])
    print(f"Yazıldı: {a.out} ve {a.sql}")
    return 1 if info["fk_errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
