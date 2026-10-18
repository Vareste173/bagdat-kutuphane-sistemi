# BAĞDAT için gerçek kitap veri seti rehberi

## Kısa cevap

- **İlk tercih:** Tek dosyada hem yayınevi hem kategori bulunan "Library Book Details" (Kaggle, revanthrampal). Açıklamasına göre Google Books API'sinden derlenmiş ve ISBN-10, ISBN-13, başlık, alt başlık, yazar, yayınevi, dil, kategori ve yayın tarihi sütunlarını içeriyor. Satır sayısını ve boş hücreleri Kaggle sayfasında kontrol edin.
- **Sizin tarif ettiğiniz durum:** Bir dosyada yayınevi var kategori yok, ötekinde kategori var yayınevi yok. Bu tam olarak **Goodreads Books** (jealousleopard) ile **7k Books with Metadata** (dylanjcastillo) çiftidir. İkisini ISBN-13 numarasıyla birleştirirsiniz.
- **Kalan boşluklar:** Open Library'den ISBN ile tek tek doldurun.
- **Gerçek üye ve ödünç verisi bulamazsınız**, çünkü kişisel veridir ve herkese açık yayımlanmaz. Üyeleri, ödünçleri ve cezaları sentetik üretmeye devam edin. Kitapların ne kadar popüler olduğu için isteğe bağlı olarak Seattle Halk Kütüphanesi'nin açık ödünç verisini kullanabilirsiniz.
- **Önemli:** Aşağıdaki sütun listeleri veri setlerinin açıklama sayfalarından alındı. Dosyaları ben indirip açamadım; ilk işiniz her dosyanın başlık satırını açıp kontrol etmek olsun.

## Önce temel kavramlar

**Veri seti** çok büyük bir Excel tablosudur. Kaggle'daki çoğu dosya CSV'dir; yani hücreleri virgülle ayrılmış düz metin.

**ISBN** kitabın "TC kimlik numarası"dır: basılan her baskının dünyada tek bir numarası vardır. Eski biçimi 10, yenisi 13 hanelidir. 10 haneli numara 13'e çevrilebilir (başına 978 eklenir, ilk 9 hane aynen kalır, son kontrol hanesi yeniden hesaplanır). Bu yüzden iki farklı dosyada bile aynı kitabı bulabilirsiniz.

**Birleştirme (merge, join)** iki listeyi ortak bir numaradan eşleştirmektir. Örnek: Bir listede öğrenci numarası ve adı, ötekinde öğrenci numarası ve notu var. Numaraya bakıp iki listeyi yan yana koyunca ad ve not aynı satırda olur. Bizde ortak numara ISBN-13'tür.

## Open Library nedir?

Open Library, herkesin kullanabildiği devasa bir kitap kataloğudur. Resmî sayfasına göre 20 milyondan fazla baskı ve yaklaşık 6 milyon yazar kayıtlıdır. Verisini iki yoldan alırsınız:

1. **Toplu indirme (data dumps).** Her ay oluşturulan dev dosyalardır: baskılar yaklaşık 9,2 GB, eserler yaklaşık 2,9 GB, yazarlar yaklaşık 0,5 GB. Her satırda tür, anahtar, sürüm numarası, son değişiklik zamanı ve kaydın tamamı JSON olarak bulunur. Bir ders projesi için fazla ağırdır; **önermiyorum.**
2. **ISBN ile sorgu (Books API).** Tarayıcıya aşağıdaki adresi yazarsanız o ISBN'in başlığı, yayınevleri, sayfa sayısı, konuları ve yazarları JSON olarak gelir:

`https://openlibrary.org/api/books?bibkeys=ISBN:9780439785969&jscmd=data&format=json`

Bu yolu yalnızca **eksik doldurmak** için kullanın; yüzlerce kitap için uygundur, milyonlarca için değil. İstekler arasına bekleme koyun ve sitenin kullanım şartlarına bakın.

Open Library'de üç kavram vardır: **eser** (work), **baskı** (edition) ve **yazar** (author). Bizim Kitaplar tablomuz baskıya yakındır. Kütüphanenizin elindeki fiziksel nüsha olan **Kitap\_Kopyalari** ise hiçbir açık veri setinde yoktur; onu siz üretirsiniz.

## Hangi veri seti ne veriyor?

| Veri seti | Bize verdikleri | Eksikleri | Not |
| --- | --- | --- | --- |
| Goodreads Books (Kaggle, jealousleopard) | başlık, yazarlar, isbn, isbn13, dil kodu, sayfa sayısı, yayın tarihi, yayınevi, puanlar | kategori yok | Yaklaşık 11 bin kitap. Yazarlar "/" ile ayrılır. Bazı satırların bozuk olduğu bildirilmiş. |
| 7k Books with Metadata (Kaggle, dylanjcastillo) | isbn13, isbn10, başlık, alt başlık, yazarlar, kategoriler, açıklama, yayın yılı, sayfa sayısı | yayınevi yok | Yaklaşık 7 bin kitap. Yazar ve kategori sütunlarında bazı boşluklar var. |
| Library Book Details (Kaggle, revanthrampal) | ISBN-10, ISBN-13, başlık, alt başlık, yayın tarihi, yazarlar, yayınevi, dil, kategori | sayfa sayısı listede görünmüyor | Google Books kaynaklı. Tek başına yetebilir. |
| Turkish Book Dataset (Kaggle, ardaakdere16) | Türkiye'deki kitaplar: başlık, yayınevi, yazar, ürün kodu, sayfa sayısı, yıl | ISBN görünmüyor ("ürün kodu" var) | ISBN ile birleşmez; başlık ve yazarla denenir. Sütun adlarını betiğe eklemeniz gerekir. |
| Book Depository Dataset (Kaggle) | ISBN-10/13, yayınevi, dil, yayın tarihi; yazar ve kategori ayrı arama tablolarında | büyük bir dosya | Yapısı bizim normalize şemamıza benzer. Ders için örneklem yeter. |
| Book-Crossing tabanlı "Books Dataset" (Kaggle, sarveshjoshi10) | ISBN, başlık, yazar, yayın yılı, yayınevi (271 bin kayıt) | kategori ve sayfa yok | Yayınevi eksiklerini doldurmak için. |
| Seattle Halk Kütüphanesi "Checkouts by Title" (data.seattle.gov) | Başlık bazında aylık ödünç sayısı, Nisan 2005'ten bugüne | üye bilgisi yok | Hangi kitabın ne kadar ödünç alındığını gösterir. Veri.gov sayfasında lisans bilgisi verilmemiş görünüyor; ödevde kaynak gösterin. |

## Birleştirme adım adım

**Mini örnek.** Goodreads'te Harry Potter'ın yayınevi var ama kategorisi yok; 7k dosyasında kategorisi var ama yayınevi yok. İkisi de aynı ISBN-13'e (9780439785969) sahip olduğu için tek satırda birleşir:

| Kaynak | isbn13 | yayınevi | kategori |
| --- | --- | --- | --- |
| Goodreads | 9780439785969 | Scholastic Inc. | boş |
| 7k Books | 9780439785969 | boş | Juvenile Fiction |
| **Sonuç** | 9780439785969 | Scholastic Inc. | Juvenile Fiction |

**Adımlar:**

1. **Dosyaları inceleyin.** Başlık satırına, satır sayısına ve boş ISBN sayısına bakın. CSV'yi Excel'de açıp kaydetmeyin; Excel uzun ISBN'leri 9,78E+12 gibi bilimsel biçime çevirip bozar. Python'da metin olarak okuyun.
2. **ISBN'i temizleyin.** Tire ve boşlukları silin. 10 haneliyse 13'e çevirin. Kontrol hanesi tutmayan numaraları anahtar olarak kullanmayın.
3. **Ortak anahtarla birleştirin ve öncelik verin.** Hangi dosyaya daha çok güveniyorsanız onu başa alın; o dosyada boş kalan hücreler sonrakilerden doldurulur.
4. **Çakışmalara karar verin.** İki dosyada farklı değer varsa (örneğin sayfa sayısı 300 ve 301) öncelikli dosya kazanır. Bunu bir kural olarak yazıp raporunuza koyun.
5. **ISBN'i olmayan satırlar.** "Başlık + ilk yazar" eşleşmesiyle denenir. Bu tam eşleşmedir; yazım farkı varsa kaçar. Gelişmiş eşleştirme (bulanık eşleştirme) yapmadıkça bu satırlara güvenmeyin.
6. **Parçalayın.** Yazarlar "/" veya ";" ile ayrılmıştır: her yazar Yazarlar'a, her kitap–yazar çifti Kitap\_Yazar'a gider. "(Translator)" yazanlar Çevirmen olur, "(Illustrator)" yazanlar yazar sayılmaz. Yayınevi ve kategori adları benzersiz hâle getirilip Yayinevleri ve Kategoriler tablolarına konur.
7. **Zorunlu alanlar.** Kitaplar tablosunda yayinevi\_id ve kategori\_id boş olamaz. Betik boşları "Bilinmeyen Yayınevi" ve "Sınıflandırılmamış" ile doldurur; isterseniz o kitapları atar.
8. **Kopyaları üretin.** Kitap\_Kopyalari gerçek veride yoktur. Betik her kitap için şube ve raf atayarak 1–3 nüsha oluşturur.
9. **Yükleyin ve doğrulayın.** Yabancı anahtar kontrolü ve denetim sorgularını çalıştırın.

## Hangi sütun hangi tabloya gider?

| Kaynak sütun | BAĞDAT karşılığı |
| --- | --- |
| başlık (+ alt başlık) | Kitaplar.kitap\_adi |
| isbn13 | Kitaplar.isbn |
| sayfa sayısı | Kitaplar.sayfa\_sayisi |
| yayın yılı ya da tarihinden yıl | Kitaplar.basim\_yili |
| dil kodu (eng, spa, fre) | Kitaplar.dil (İngilizce, İspanyolca, Fransızca) |
| açıklama | Kitaplar.ozet |
| yayınevi | Yayinevleri.yayinevi\_adi ve Kitaplar.yayinevi\_id |
| kategorinin ilk parçası | Kategoriler.kategori\_adi ve Kitaplar.kategori\_id |
| yazarlar | Yazarlar.ad, soyad ve Kitap\_Yazar |
| kaynakta yok | Raflar, Kitap\_Kopyalari, Uyeler, Odunc\_Islemleri, Cezalar vb. (sentetik) |

## Betiği çalıştırma

Gerekenler: Python 3 ve `pip install pandas`. Şema dosyası olarak daha önce verdiğim `bagdat_schema.sql` kullanılır. Dosya sırası önceliktir.

`python bagdat_gercek_katalog_yukle.py --schema bagdat_schema.sql --out bagdat_gercek.db goodreads.csv 7k_books.csv --max-books 2000`

Betik önce her dosya için bir rapor yazar: kaç satır var, kaç satır bozuk, kaç ISBN eksik, kaç satır iki dosyada ortak, hangi sütunlarda kaç boşluk doldurulmuş. Sonra `bagdat_gercek.db` ve `bagdat_gercek_katalog.sql` dosyalarını üretir. Sütun adları sizin dosyanızda farklıysa betiğin başındaki SYNONYMS sözlüğüne yeni adı ekleyin. Deneme için yanında iki küçük **sahte** örnek CSV de var.

## Neyi test ettim, neyi etmedim?

- Betiği, bu veri setleriyle aynı sütun adlarını taşıyan **sahte** küçük dosyalarla sınadım. ISBN-10'dan 13'e çevirim, ortak anahtarla birleştirme, boşluk doldurma, tekrar eden satırı ayıklama, hatalı ISBN'i anahtar yapmama, çizerin yazar sayılmaması, yabancı anahtar kontrolü ve üretilen SQL'in boş veritabanına yüklenmesi geçti. 11 bin satırlık sahte iki dosya yaklaşık 1 saniyede işlendi.
- **Gerçek dosyalarla denemedim**; bu ortamdan Kaggle'a erişemiyorum. İlk çalıştırmada raporu okuyup sayıları kontrol edin.
- Veri setlerinin lisansını ve kullanım şartlarını kendi sayfalarında kontrol edin; ödevde kaynak gösterin.
- "Yüzde yüz doğruluk" kaynağa bağlıdır: gerçek veride de boş ve hatalı değerler olur. Bu yüzden birleştirmeden sonra denetim sorgularını mutlaka çalıştırın.

## Sonraki adım

Şu an üye, ödünç, ceza ve masa verisini üreten betiğim kendi kitaplarını da üretiyor. İsterseniz onu gerçek kataloğun üstüne oturtacak şekilde güncellerim; böylece katalog gerçek, hareketler sentetik ama kurallara uygun olur.
