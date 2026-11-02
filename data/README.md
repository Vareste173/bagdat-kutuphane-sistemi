# Veri dosyaları

Bu klasör, BAĞDAT katalog (Modül 2) verisinin kaynağını ve dönüştürme adımlarını belgeler. Üye, personel, ödünç, ceza ve rezervasyon verileri **gerçek kişilere ait değildir**; sentetik olarak üretilir.

## Dosyalar

| Dosya | Açıklama |
|---|---|
| `books.csv` | Goodreads Books ham verisi (11.127 kayıt). Sütunlar: `bookID, title, authors, average_rating, isbn, isbn13, language_code, num_pages, ratings_count, text_reviews_count, publication_date, publisher` |
| `bagdat_birlestirilmis_katalog.csv` | Kaynakların ISBN-13 ile birleştirilmiş, projede kullanılan kataloğu (12.242 kayıt). Sütunlar: `isbn13, title, authors, publisher, categories, num_pages, average_rating, publication_date` |
| `ornek/*_SAHTE.csv` | Betiği denemek için üretilmiş **sahte** küçük örnekler; gerçek veri değildir. |

## Kaynaklar

| Kaynak | Bağlantı | Lisans / koşul | İndirme tarihi |
|---|---|---|---|
| Goodreads Books (Kaggle, jealousleopard) | _eklenecek_ | _Kaggle sayfasından kontrol edilip yazılacak_ | _eklenecek_ |
| 7k Books with Metadata (Kaggle, dylanjcastillo) | _eklenecek_ | _Kaggle sayfasından kontrol edilip yazılacak_ | _eklenecek_ |

> Birleştirmede başka bir kaynak da kullanıldıysa yukarıya eklenmelidir.

## Dönüştürme adımları

Ayrıntılı rehber: [`docs/veri_seti_rehberi.md`](../docs/veri_seti_rehberi.md). Betik: [`tools/bagdat_gercek_katalog_yukle.py`](../tools/bagdat_gercek_katalog_yukle.py).

1. ISBN'ler temizlenir (tire ve boşluk silinir), 10 haneliler 13'e çevrilir.
2. Dosyalar ISBN-13 ile birleştirilir. Dosya sırası önceliktir: ilk dosyadaki dolu değer korunur, boş hücreler sonrakilerden doldurulur.
3. Çakışmada öncelikli dosya kazanır.
4. Yazarlar ayrıştırılır; çevirmen ve çizer yazar sayılmaz.
5. Kategorisi bilinmeyen kitaplar `Genel / Sınıflandırılmamış` olarak işaretlenir.
6. Fiziksel nüshalar (`Kitap_Kopyalari`), raflar ve şubeler kaynakta yoktur; betik bunları üretir.

## Bilinen sınırlar

- Birleştirilmiş katalogda **`num_pages` sütunu boştur**; bu nedenle `Kitaplar.sayfa_sayisi` doldurulamaz ve boş bırakılabilir olmalıdır.
- Kitapların yaklaşık yarısı (5.531 / 12.242) `Genel / Sınıflandırılmamış` kategorisindedir.
- Kaynak veri gerçek dünyada olduğu gibi boş ve hatalı değerler içerebilir; yükleme sonrası denetim sorguları çalıştırılmalıdır.
