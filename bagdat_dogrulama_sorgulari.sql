-- BAĞDAT doğrulama sorguları: her sorgu 0 satır döndürmelidir (satır = hatalı kayıt).
-- SQLite sözdizimiyle yazıldı; tarih fonksiyonları MySQL/SQL Server'da değişebilir.

-- 1. Yabancı anahtar bütünlüğü
PRAGMA foreign_key_check;

-- 2. Bir kopya aynı anda en fazla bir açık ödüncte olabilir
SELECT kopya_id FROM Odunc_Islemleri WHERE teslim_edildigi_tarih IS NULL AND durum IN ('Aktif','Gecikmiş') GROUP BY kopya_id HAVING COUNT(*)>1;

-- 3. Kopya 'Ödünçte' ise açık bir ödünç kaydı olmalı
SELECT k.kopya_id FROM Kitap_Kopyalari k WHERE k.durum='Ödünçte' AND NOT EXISTS (SELECT 1 FROM Odunc_Islemleri o WHERE o.kopya_id=k.kopya_id AND o.teslim_edildigi_tarih IS NULL AND o.durum IN ('Aktif','Gecikmiş'));

-- 4. Açık ödüncün kopyası 'Ödünçte' olmalı
SELECT o.odunc_id FROM Odunc_Islemleri o JOIN Kitap_Kopyalari k ON k.kopya_id=o.kopya_id WHERE o.teslim_edildigi_tarih IS NULL AND o.durum IN ('Aktif','Gecikmiş') AND k.durum<>'Ödünçte';

-- 5. Ödünç durumu ile iade tarihi ve son teslim tarihi çelişmemeli
SELECT odunc_id FROM Odunc_Islemleri WHERE (durum='İade Edildi' AND teslim_edildigi_tarih IS NULL) OR (durum IN ('Aktif','Gecikmiş','Kayıp') AND teslim_edildigi_tarih IS NOT NULL) OR (durum='Gecikmiş' AND son_teslim_tarihi >= '2026-10-17') OR (durum='Aktif' AND son_teslim_tarihi < '2026-10-17');

-- 6. Son teslim tarihi = ödünç tarihi + üyelik tipinin gün sayısı + 7 x uzatma
SELECT o.odunc_id FROM Odunc_Islemleri o JOIN Uyeler u ON u.uye_id=o.uye_id JOIN Uyelik_Tipleri t ON t.uyelik_tipi_id=u.uyelik_tipi_id WHERE CAST(julianday(o.son_teslim_tarihi)-julianday(o.odunc_tarihi) AS INT) <> t.max_odunc_gun + 7*o.uzatma_sayisi;

-- 7. Uzatma sayısı = Odunc_Uzatmalar satır sayısı ve tipin hakkını aşmamalı
SELECT o.odunc_id FROM Odunc_Islemleri o JOIN Uyeler u ON u.uye_id=o.uye_id JOIN Uyelik_Tipleri t ON t.uyelik_tipi_id=u.uyelik_tipi_id LEFT JOIN (SELECT odunc_id, COUNT(*) n, MAX(yeni_son_tarih) m FROM Odunc_Uzatmalar GROUP BY odunc_id) x ON x.odunc_id=o.odunc_id WHERE o.uzatma_sayisi <> COALESCE(x.n,0) OR o.uzatma_sayisi > t.max_uzatma_sayisi OR (x.n IS NOT NULL AND o.son_teslim_tarihi <> x.m);

-- 8. Üye, tipinin izin verdiğinden fazla kitabı aynı anda tutmamalı
SELECT a.odunc_id FROM Odunc_Islemleri a JOIN Uyeler u ON u.uye_id=a.uye_id JOIN Uyelik_Tipleri t ON t.uyelik_tipi_id=u.uyelik_tipi_id WHERE (SELECT COUNT(*) FROM Odunc_Islemleri b WHERE b.uye_id=a.uye_id AND b.odunc_tarihi<=a.odunc_tarihi AND COALESCE(b.teslim_edildigi_tarih,'9999-12-31') > a.odunc_tarihi) > t.max_kitap_hakki;

-- 9. Kapalı üyeye ödünç verilmemeli, ödünç tarihi kayıt tarihinden önce olmamalı
SELECT o.odunc_id FROM Odunc_Islemleri o JOIN Uyeler u ON u.uye_id=o.uye_id WHERE u.durum<>'Aktif' OR o.odunc_tarihi < u.kayit_tarihi;

-- 10. Gecikme cezası: gün sayısı ve tutar (gün x günlük ceza) doğru olmalı
SELECT c.ceza_id FROM Cezalar c JOIN Odunc_Islemleri o ON o.odunc_id=c.odunc_id JOIN Uyeler u ON u.uye_id=o.uye_id JOIN Uyelik_Tipleri t ON t.uyelik_tipi_id=u.uyelik_tipi_id WHERE c.ceza_turu='Gecikme' AND (c.gecikme_gun <> CAST(julianday(o.teslim_edildigi_tarih)-julianday(o.son_teslim_tarihi) AS INT) OR ABS(c.toplam_tutar - c.gecikme_gun*t.gunluk_ceza_tutari) > 0.005);

-- 11. Geç iade edilen her ödünç için tam bir gecikme cezası olmalı, zamanında iadede olmamalı
SELECT o.odunc_id FROM Odunc_Islemleri o WHERE (o.teslim_edildigi_tarih > o.son_teslim_tarihi AND (SELECT COUNT(*) FROM Cezalar c WHERE c.odunc_id=o.odunc_id AND c.ceza_turu='Gecikme') <> 1) OR ((o.teslim_edildigi_tarih IS NULL OR o.teslim_edildigi_tarih <= o.son_teslim_tarihi) AND EXISTS (SELECT 1 FROM Cezalar c WHERE c.odunc_id=o.odunc_id AND c.ceza_turu='Gecikme'));

-- 12. Hasar ve kayıp cezaları hasar kaydına bağlı olmalı ve tutarı tazminata eşit olmalı
SELECT c.ceza_id FROM Cezalar c LEFT JOIN Hasar_Kayitlari h ON h.hasar_id=c.hasar_id WHERE (c.ceza_turu IN ('Hasar','Kayıp') AND (h.hasar_id IS NULL OR ABS(c.toplam_tutar-h.tazminat_tutari)>0.005 OR h.odunc_id<>c.odunc_id)) OR (c.ceza_turu='Gecikme' AND c.hasar_id IS NOT NULL);

-- 13. Ödeme durumu ile ödemelerin toplamı uyumlu olmalı (Ödendi = tam, Kısmi = eksik, diğerleri = ödeme yok)
SELECT c.ceza_id FROM Cezalar c LEFT JOIN (SELECT ceza_id, SUM(tutar) s FROM Ceza_Odemeleri GROUP BY ceza_id) p ON p.ceza_id=c.ceza_id WHERE NOT ((c.odeme_durumu='Ödendi' AND ABS(COALESCE(p.s,0)-c.toplam_tutar)<0.005) OR (c.odeme_durumu='Kısmi' AND p.s>0 AND p.s<c.toplam_tutar-0.005) OR (c.odeme_durumu IN ('Ödenmedi','Affedildi') AND p.s IS NULL));

-- 14. Hasar kaydındaki kopya, bağlı ödüncün kopyasıyla aynı olmalı; kayıp kopyanın 'Kayıp' hasar kaydı olmalı
SELECT h.hasar_id FROM Hasar_Kayitlari h JOIN Odunc_Islemleri o ON o.odunc_id=h.odunc_id WHERE o.kopya_id<>h.kopya_id UNION ALL SELECT k.kopya_id FROM Kitap_Kopyalari k WHERE k.durum='Kayıp' AND NOT EXISTS (SELECT 1 FROM Hasar_Kayitlari h WHERE h.kopya_id=k.kopya_id AND h.hasar_turu='Kayıp');

-- 15. Kopyanın rafı, kopyanın şubesindeki bir raf olmalı
SELECT k.kopya_id FROM Kitap_Kopyalari k JOIN Raflar r ON r.raf_id=k.raf_id WHERE r.sube_id<>k.sube_id;

-- 16. Her kitabın en az bir yazarı, her üyenin tam bir kartı olmalı
SELECT kitap_id FROM Kitaplar k WHERE NOT EXISTS (SELECT 1 FROM Kitap_Yazar y WHERE y.kitap_id=k.kitap_id) UNION ALL SELECT uye_id FROM Uyeler u WHERE (SELECT COUNT(*) FROM Kutuphane_Kartlari c WHERE c.uye_id=u.uye_id)<>1;

-- 17. Kitap rezervasyonu: 'Beklemede' yalnız rafta kopyası olmayan kitapta, sıra numaraları 1..n
SELECT r.kitap_id FROM Kitap_Rezervasyonlari r WHERE r.durum='Beklemede' AND EXISTS (SELECT 1 FROM Kitap_Kopyalari k WHERE k.kitap_id=r.kitap_id AND k.durum='Rafta') UNION ALL SELECT kitap_id FROM (SELECT kitap_id, COUNT(*) n, MAX(sira_no) m, COUNT(DISTINCT sira_no) d FROM Kitap_Rezervasyonlari WHERE durum='Beklemede' GROUP BY kitap_id) WHERE n<>m OR n<>d;

-- 18. 'Hazır' rezervasyonun kopyası 'Rezerve' olmalı ve her 'Rezerve' kopyanın hazır rezervasyonu olmalı
SELECT r.kitap_rezervasyon_id FROM Kitap_Rezervasyonlari r JOIN Kitap_Kopyalari k ON k.kopya_id=r.ayrilan_kopya_id WHERE r.durum='Hazır' AND (k.durum<>'Rezerve' OR k.kitap_id<>r.kitap_id) UNION ALL SELECT k.kopya_id FROM Kitap_Kopyalari k WHERE k.durum='Rezerve' AND NOT EXISTS (SELECT 1 FROM Kitap_Rezervasyonlari r WHERE r.ayrilan_kopya_id=k.kopya_id AND r.durum='Hazır');

-- 19. Aynı masada ya da aynı üyede çakışan masa rezervasyonu olmamalı
SELECT a.rezervasyon_id FROM Masa_Rezervasyonlari a JOIN Masa_Rezervasyonlari b ON a.rezervasyon_id<b.rezervasyon_id AND a.baslangic_saati<b.bitis_saati AND b.baslangic_saati<a.bitis_saati AND (a.masa_id=b.masa_id OR a.uye_id=b.uye_id) WHERE a.durum<>'İptal' AND b.durum<>'İptal';

-- 20. Masa rezervasyonu: durum, zaman ve giriş bilgisi uyumlu; arızalı masa rezerve edilmemeli
SELECT r.rezervasyon_id FROM Masa_Rezervasyonlari r JOIN Masalar m ON m.masa_id=r.masa_id WHERE (r.durum='Aktif' AND r.baslangic_saati < '2026-10-17') OR (r.durum IN ('Tamamlandı','Gelmedi') AND r.baslangic_saati >= '2026-10-17') OR (r.durum='Tamamlandı' AND r.giris_zamani IS NULL) OR (r.durum<>'Tamamlandı' AND r.giris_zamani IS NOT NULL) OR m.durum<>'Aktif';

-- 21. Etkinlik: katılımcı sayısı kontenjanı aşmamalı, 'katıldı' yalnız tamamlanmış etkinlikte olmalı
SELECT e.etkinlik_id FROM Etkinlikler e WHERE (SELECT COUNT(*) FROM Etkinlik_Katilimcilari k WHERE k.etkinlik_id=e.etkinlik_id) > e.kontenjan UNION ALL SELECT k.etkinlik_id FROM Etkinlik_Katilimcilari k JOIN Etkinlikler e ON e.etkinlik_id=k.etkinlik_id WHERE k.katildi_mi=1 AND e.durum<>'Tamamlandı';

-- 22. Okuma_Istatistikleri: 5 sayaç, ödünç/iade/masa/etkinlik kayıtlarından yeniden hesaplanınca birebir eşleşmeli
SELECT s.istatistik_id FROM Okuma_Istatistikleri s WHERE s.alinan_kitap_sayisi <> (SELECT COUNT(*) FROM Odunc_Islemleri o WHERE o.uye_id=s.uye_id AND CAST(strftime('%Y',o.odunc_tarihi) AS INT)=s.yil AND CAST(strftime('%m',o.odunc_tarihi) AS INT)=s.ay) OR s.zamaninda_iade_sayisi <> (SELECT COUNT(*) FROM Odunc_Islemleri o WHERE o.uye_id=s.uye_id AND o.teslim_edildigi_tarih<=o.son_teslim_tarihi AND CAST(strftime('%Y',o.teslim_edildigi_tarih) AS INT)=s.yil AND CAST(strftime('%m',o.teslim_edildigi_tarih) AS INT)=s.ay) OR s.geciken_iade_sayisi <> (SELECT COUNT(*) FROM Odunc_Islemleri o WHERE o.uye_id=s.uye_id AND o.teslim_edildigi_tarih>o.son_teslim_tarihi AND CAST(strftime('%Y',o.teslim_edildigi_tarih) AS INT)=s.yil AND CAST(strftime('%m',o.teslim_edildigi_tarih) AS INT)=s.ay) OR ABS(s.masa_kullanim_saati - COALESCE((SELECT SUM((julianday(m.bitis_saati)-julianday(m.baslangic_saati))*24) FROM Masa_Rezervasyonlari m WHERE m.uye_id=s.uye_id AND m.durum='Tamamlandı' AND CAST(strftime('%Y',m.baslangic_saati) AS INT)=s.yil AND CAST(strftime('%m',m.baslangic_saati) AS INT)=s.ay),0)) > 0.01 OR s.etkinlik_katilim_sayisi <> (SELECT COUNT(*) FROM Etkinlik_Katilimcilari k JOIN Etkinlikler e ON e.etkinlik_id=k.etkinlik_id WHERE k.uye_id=s.uye_id AND k.katildi_mi=1 AND e.durum='Tamamlandı' AND CAST(strftime('%Y',e.baslangic_zamani) AS INT)=s.yil AND CAST(strftime('%m',e.baslangic_zamani) AS INT)=s.ay);

-- 23. Okuma_Istatistikleri: hareketi olan her üye-ay için satır olmalı (eksik satır yok)
SELECT a.uye_id FROM (SELECT uye_id, strftime('%Y-%m',odunc_tarihi) ym FROM Odunc_Islemleri UNION SELECT uye_id, strftime('%Y-%m',teslim_edildigi_tarih) FROM Odunc_Islemleri WHERE teslim_edildigi_tarih IS NOT NULL UNION SELECT uye_id, strftime('%Y-%m',baslangic_saati) FROM Masa_Rezervasyonlari WHERE durum='Tamamlandı' UNION SELECT k.uye_id, strftime('%Y-%m',e.baslangic_zamani) FROM Etkinlik_Katilimcilari k JOIN Etkinlikler e ON e.etkinlik_id=k.etkinlik_id WHERE k.katildi_mi=1 AND e.durum='Tamamlandı') a WHERE NOT EXISTS (SELECT 1 FROM Okuma_Istatistikleri s WHERE s.uye_id=a.uye_id AND printf('%04d-%02d',s.yil,s.ay)=a.ym);

-- 24. Okuma_Istatistikleri: puan = 2 x alınan + 3 x zamanında - 2 x geciken + 5 x etkinlik + masa saati (tam kısım)
SELECT istatistik_id FROM Okuma_Istatistikleri WHERE puan <> 2*alinan_kitap_sayisi + 3*zamaninda_iade_sayisi - 2*geciken_iade_sayisi + 5*etkinlik_katilim_sayisi + CAST(masa_kullanim_saati AS INT);

-- 25. Ayın ödülleri: ödülü alan, o ayın istatistiğinde kuralı sağlayan gerçek birinci olmalı
SELECT o.odul_id FROM Ayin_Odulleri o JOIN Okuma_Istatistikleri s ON s.istatistik_id=o.istatistik_id WHERE o.uye_id<>s.uye_id OR (o.odul_turu='Ayın Okuru' AND s.uye_id <> (SELECT x.uye_id FROM Okuma_Istatistikleri x WHERE x.yil=s.yil AND x.ay=s.ay AND x.alinan_kitap_sayisi>=1 ORDER BY x.alinan_kitap_sayisi DESC, x.uye_id LIMIT 1)) OR (o.odul_turu='En Düzenli Üye' AND s.uye_id <> (SELECT x.uye_id FROM Okuma_Istatistikleri x WHERE x.yil=s.yil AND x.ay=s.ay AND x.geciken_iade_sayisi=0 AND x.zamaninda_iade_sayisi>=1 ORDER BY x.zamaninda_iade_sayisi DESC, x.uye_id LIMIT 1)) OR (o.odul_turu='En Aktif Salon Kullanıcısı' AND s.uye_id <> (SELECT x.uye_id FROM Okuma_Istatistikleri x WHERE x.yil=s.yil AND x.ay=s.ay AND x.masa_kullanim_saati>0 ORDER BY x.masa_kullanim_saati DESC, x.uye_id LIMIT 1));

-- Çapraz kontroller: sonuçlar bağımsız hesapla eşleşmelidir
-- C1. En çok ödünç alınan 5 kitap (kitap_id sırası)
SELECT k.kitap_id FROM Odunc_Islemleri o JOIN Kitap_Kopyalari k ON k.kopya_id=o.kopya_id GROUP BY k.kitap_id ORDER BY COUNT(*) DESC, k.kitap_id LIMIT 5;

-- C2. Toplam ödünç sayısı
SELECT COUNT(*) FROM Odunc_Islemleri;

-- C3. Şube bazında ödünç sayıları
SELECT k.sube_id, COUNT(*) FROM Odunc_Islemleri o JOIN Kitap_Kopyalari k ON k.kopya_id=o.kopya_id GROUP BY k.sube_id;

-- C4. Şu an gecikmiş açık ödünç sayısı
SELECT COUNT(*) FROM Odunc_Islemleri WHERE durum='Gecikmiş';

-- C5. Toplam ödenmemiş ceza bakiyesi (affedilenler hariç)
SELECT ROUND(SUM(c.toplam_tutar) - COALESCE(SUM(p.s),0),2) FROM Cezalar c LEFT JOIN (SELECT ceza_id, SUM(tutar) s FROM Ceza_Odemeleri GROUP BY ceza_id) p ON p.ceza_id=c.ceza_id WHERE c.odeme_durumu<>'Affedildi';

