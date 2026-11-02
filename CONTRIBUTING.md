# Katkı Rehberi

Bu belge, BAĞDAT projesinde dört kişinin aynı depoda birbirinin işini bozmadan çalışması için kuralları toplar. Temel kural: **test yok, inceleme yok, birleştirme yok.**

## Reviewer sırası

| PR'ı açan | İnceleyen |
|---|---|
| İrem Çelik | Hayrunnisa Sarı |
| Hayrunnisa Sarı | Saliha Esma Sönmezsoy |
| Saliha Esma Sönmezsoy | Medine Gül Enser |
| Medine Gül Enser | İrem Çelik |

İnceleyen kişi yalnızca "okudum" demez; dalı çeker ve testleri kendi makinesinde çalıştırır.

## Bir görevin yaşam döngüsü

1. **Başla:** Jira'da görevi "Devam Ediyor" yapın. Her görevin tek bir atanan kişisi vardır.
2. **Dal aç:** `main` güncel olsun, sonra dal açın.
   ```bash
   git checkout main && git pull
   git checkout -b feature/BAG-11-odunc-yordamlari
   ```
3. **Çalış:** Küçük ve sık commit atın. Mesaj biçimi: `BAG-11: sp_iade_al gecikme cezası eklendi`
4. **Test yaz ve çalıştır:** Görevin test dosyası PR ile birlikte gelir (`tests/modulX/BAG-N_test.sql`). Yerelde `bash tests/run_all.sh` geçmelidir.
5. **PR aç:** Başlık BAG-11: ile başlar, açıklamada neyin yapıldığı, nasıl test edildiği ve reviewer için notlar yazılır, reviewer olarak sıradaki kişi seçilir
6. **İnceleme:** Reviewer kodu okur, testleri çalıştırır, yorum bırakır veya onaylar.
7. **Birleştir:** En az 1 onay ve geçen testlerden sonra **Squash and merge**. Dal silinir.
8. **Bitir:** Jira'da görev "Bitti" olur. Birleştirmeyi yapan kişi bunu kontrol eder.

## Bitti sayılma ölçütü

- Dosyalar klasör yapısındaki doğru yerde.
- Dosya temiz bir veritabanında hatasız çalışıyor (`install.sql` ile birlikte).
- Testler yazıldı, hem olumlu hem olumsuz durumları kapsıyor ve geçiyor.
- PR açıklaması dolduruldu; en az 1 kişi inceleyip onayladı.
- Her tablo, yordam ve tetikleyicinin neden var olduğu bir cümleyle yorum satırında yazılı.
- Jira görevi güncel (durum, PR bağlantısı).

## Dal ve çakışma kuralları

- **`main` dalına doğrudan push yapılmaz.**
- Herkes yalnızca kendi modül klasöründe çalışır (`sql/0X_modulX/`, `tests/modulX/`). Ortak dosyalar (`install.sql`, `00_setup.sql`, `README.md`) için önce ilgili kişiye haber verilir.
- Bir görev, bir PR. 400 satırı çok aşan PR bölünür.
- Bir PR'ın incelenmesi 24 saatten uzun beklemez; bekleyen PR ekip sohbetinde hatırlatılır.

## Test yazma

Testler ek kütüphane gerektirmeden `psql` ve PL/pgSQL ile yazılır. Her test dosyası bir işlem içinde çalışır ve sonunda `ROLLBACK` yapar.

- **Olumlu test:** geçerli işlem başarılı olmalı.
- **Olumsuz test:** hatalı veri reddedilmeli; beklenmeyen durumda `RAISE EXCEPTION 'TEST BASARISIZ: ...'` ile test düşer.
- Bir yordamın başarısı kadar, hatalı girdide **hiçbir kaydın değişmediği** de test edilir.

Dosya adı: `tests/modulX/BAG-N_test.sql`. Modüller arası testler `tests/ortak/` altına konur.

## Kurulum

Ayrıntılar için [README.md](README.md) dosyasındaki "Kurulum ve çalıştırma" bölümüne bakın.
