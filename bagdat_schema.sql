CREATE TABLE Uyelik_Tipleri (
  uyelik_tipi_id INTEGER PRIMARY KEY AUTOINCREMENT,
  tip_adi VARCHAR(50) NOT NULL UNIQUE,
  max_kitap_hakki INTEGER NOT NULL CHECK (max_kitap_hakki > 0),
  max_odunc_gun INTEGER NOT NULL CHECK (max_odunc_gun > 0),
  max_uzatma_sayisi INTEGER DEFAULT 1,
  gunluk_ceza_tutari DECIMAL(6,2) DEFAULT 0 CHECK (gunluk_ceza_tutari >= 0)
);

CREATE TABLE Subeler (
  sube_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sube_adi VARCHAR(100) NOT NULL UNIQUE,
  sehir VARCHAR(50),
  adres VARCHAR(255),
  telefon VARCHAR(20),
  acilis_saati TIME,
  kapanis_saati TIME,
  aktif_mi BOOLEAN DEFAULT 1 CHECK (aktif_mi IN (0,1))
);

CREATE TABLE Uyeler (
  uye_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uyelik_tipi_id INTEGER NOT NULL,
  kayit_sube_id INTEGER,
  ad VARCHAR(50) NOT NULL,
  soyad VARCHAR(50) NOT NULL,
  eposta VARCHAR(100) NOT NULL UNIQUE,
  telefon VARCHAR(20),
  dogum_tarihi DATE,
  sifre_hash VARCHAR(255) NOT NULL,
  kayit_tarihi DATE DEFAULT (date('now')),
  uyelik_bitis_tarihi DATE,
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'Askıda', 'Kapalı')),
  FOREIGN KEY (uyelik_tipi_id) REFERENCES Uyelik_Tipleri(uyelik_tipi_id),
  FOREIGN KEY (kayit_sube_id) REFERENCES Subeler(sube_id)
);

CREATE TABLE Kutuphane_Kartlari (
  kart_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL UNIQUE,
  barkod_no VARCHAR(30) NOT NULL UNIQUE,
  verilme_tarihi DATE NOT NULL,
  gecerlilik_bitis DATE,
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'Kayıp', 'İptal')),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id)
);

CREATE TABLE Roller (
  rol_id INTEGER PRIMARY KEY AUTOINCREMENT,
  rol_adi VARCHAR(50) NOT NULL UNIQUE,
  yetki_aciklamasi VARCHAR(255)
);

CREATE TABLE Personel (
  personel_id INTEGER PRIMARY KEY AUTOINCREMENT,
  rol_id INTEGER NOT NULL,
  sube_id INTEGER NOT NULL,
  ust_personel_id INTEGER,
  ad VARCHAR(50) NOT NULL,
  soyad VARCHAR(50) NOT NULL,
  eposta VARCHAR(100) NOT NULL UNIQUE,
  telefon VARCHAR(20),
  sifre_hash VARCHAR(255) NOT NULL,
  ise_baslama_tarihi DATE,
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'İzinli', 'Ayrıldı')),
  FOREIGN KEY (rol_id) REFERENCES Roller(rol_id),
  FOREIGN KEY (sube_id) REFERENCES Subeler(sube_id),
  FOREIGN KEY (ust_personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Bildirimler (
  bildirim_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  tur VARCHAR(30) CHECK (tur IN ('İade Hatırlatma', 'Rezervasyon Hazır', 'Ceza', 'Etkinlik', 'Genel')),
  baslik VARCHAR(100),
  mesaj VARCHAR(500) NOT NULL,
  kanal VARCHAR(10) CHECK (kanal IN ('E-posta', 'SMS', 'Uygulama')),
  olusturma_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
  okundu_mu BOOLEAN DEFAULT 0 CHECK (okundu_mu IN (0,1)),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id)
);

CREATE TABLE Denetim_Loglari (
  log_id INTEGER PRIMARY KEY AUTOINCREMENT,
  personel_id INTEGER,
  tablo_adi VARCHAR(60) NOT NULL,
  kayit_id INTEGER,
  islem_turu VARCHAR(10) CHECK (islem_turu IN ('INSERT', 'UPDATE', 'DELETE')),
  eski_deger TEXT,
  yeni_deger TEXT,
  islem_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
  ip_adresi VARCHAR(45),
  FOREIGN KEY (personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Yayinevleri (
  yayinevi_id INTEGER PRIMARY KEY AUTOINCREMENT,
  yayinevi_adi VARCHAR(150) NOT NULL UNIQUE,
  sehir VARCHAR(50),
  eposta VARCHAR(100),
  web_sitesi VARCHAR(150)
);

CREATE TABLE Kategoriler (
  kategori_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ust_kategori_id INTEGER,
  kategori_adi VARCHAR(100) NOT NULL,
  dewey_kodu VARCHAR(10),
  aciklama VARCHAR(255),
  UNIQUE (ust_kategori_id, kategori_adi),
  FOREIGN KEY (ust_kategori_id) REFERENCES Kategoriler(kategori_id)
);

CREATE TABLE Yazarlar (
  yazar_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ad VARCHAR(50) NOT NULL,
  soyad VARCHAR(50) NOT NULL,
  dogum_yili INTEGER,
  olum_yili INTEGER,
  uyruk VARCHAR(50),
  biyografi TEXT,
  CHECK (olum_yili IS NULL OR dogum_yili IS NULL OR olum_yili >= dogum_yili)
);

CREATE TABLE Kitaplar (
  kitap_id INTEGER PRIMARY KEY AUTOINCREMENT,
  yayinevi_id INTEGER NOT NULL,
  kategori_id INTEGER NOT NULL,
  kitap_adi VARCHAR(250) NOT NULL,
  isbn VARCHAR(17) UNIQUE,
  basim_yili INTEGER,
  baski_no INTEGER DEFAULT 1,
  sayfa_sayisi INTEGER CHECK (sayfa_sayisi > 0),
  dil VARCHAR(30) DEFAULT 'Türkçe',
  ozet TEXT,
  CHECK (basim_yili IS NULL OR basim_yili >= 1450),
  FOREIGN KEY (yayinevi_id) REFERENCES Yayinevleri(yayinevi_id),
  FOREIGN KEY (kategori_id) REFERENCES Kategoriler(kategori_id)
);

CREATE TABLE Kitap_Yazar (
  kitap_id INTEGER NOT NULL,
  yazar_id INTEGER NOT NULL,
  yazar_sirasi INTEGER DEFAULT 1,
  katki_turu VARCHAR(15) DEFAULT 'Yazar' CHECK (katki_turu IN ('Yazar', 'Çevirmen', 'Editör')),
  PRIMARY KEY (kitap_id, yazar_id),
  FOREIGN KEY (kitap_id) REFERENCES Kitaplar(kitap_id),
  FOREIGN KEY (yazar_id) REFERENCES Yazarlar(yazar_id)
);

CREATE TABLE Raflar (
  raf_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sube_id INTEGER NOT NULL,
  raf_kodu VARCHAR(20) NOT NULL,
  bolum_adi VARCHAR(80),
  kat INTEGER,
  kapasite INTEGER CHECK (kapasite > 0),
  UNIQUE (sube_id, raf_kodu),
  FOREIGN KEY (sube_id) REFERENCES Subeler(sube_id)
);

CREATE TABLE Kitap_Kopyalari (
  kopya_id INTEGER PRIMARY KEY AUTOINCREMENT,
  kitap_id INTEGER NOT NULL,
  sube_id INTEGER NOT NULL,
  raf_id INTEGER,
  barkod VARCHAR(30) NOT NULL UNIQUE,
  durum VARCHAR(15) DEFAULT 'Rafta' CHECK (durum IN ('Rafta', 'Ödünçte', 'Rezerve', 'Hasarlı', 'Kayıp', 'Bakımda')),
  edinme_turu VARCHAR(15) CHECK (edinme_turu IN ('Satın Alma', 'Bağış')),
  edinme_tarihi DATE,
  fiyat DECIMAL(8,2) CHECK (fiyat >= 0),
  FOREIGN KEY (kitap_id) REFERENCES Kitaplar(kitap_id),
  FOREIGN KEY (sube_id) REFERENCES Subeler(sube_id),
  FOREIGN KEY (raf_id) REFERENCES Raflar(raf_id)
);

CREATE TABLE Odunc_Islemleri (
  odunc_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  kopya_id INTEGER NOT NULL,
  veren_personel_id INTEGER NOT NULL,
  teslim_alan_personel_id INTEGER,
  odunc_tarihi DATE NOT NULL DEFAULT (date('now')),
  son_teslim_tarihi DATE NOT NULL,
  teslim_edildigi_tarih DATE,
  uzatma_sayisi INTEGER DEFAULT 0 CHECK (uzatma_sayisi >= 0),
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'İade Edildi', 'Gecikmiş', 'Kayıp')),
  CHECK (son_teslim_tarihi >= odunc_tarihi),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id),
  FOREIGN KEY (kopya_id) REFERENCES Kitap_Kopyalari(kopya_id),
  FOREIGN KEY (veren_personel_id) REFERENCES Personel(personel_id),
  FOREIGN KEY (teslim_alan_personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Odunc_Uzatmalar (
  uzatma_id INTEGER PRIMARY KEY AUTOINCREMENT,
  odunc_id INTEGER NOT NULL,
  personel_id INTEGER,
  eski_son_tarih DATE NOT NULL,
  yeni_son_tarih DATE NOT NULL,
  uzatma_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
  CHECK (yeni_son_tarih > eski_son_tarih),
  FOREIGN KEY (odunc_id) REFERENCES Odunc_Islemleri(odunc_id),
  FOREIGN KEY (personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Kitap_Rezervasyonlari (
  kitap_rezervasyon_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  kitap_id INTEGER NOT NULL,
  ayrilan_kopya_id INTEGER,
  talep_zamani DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sira_no INTEGER CHECK (sira_no > 0),
  durum VARCHAR(15) DEFAULT 'Beklemede' CHECK (durum IN ('Beklemede', 'Hazır', 'Teslim Alındı', 'İptal', 'Süresi Doldu')),
  son_alma_zamani DATETIME,
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id),
  FOREIGN KEY (kitap_id) REFERENCES Kitaplar(kitap_id),
  FOREIGN KEY (ayrilan_kopya_id) REFERENCES Kitap_Kopyalari(kopya_id)
);

CREATE TABLE Hasar_Kayitlari (
  hasar_id INTEGER PRIMARY KEY AUTOINCREMENT,
  kopya_id INTEGER NOT NULL,
  odunc_id INTEGER,
  personel_id INTEGER NOT NULL,
  hasar_turu VARCHAR(20) CHECK (hasar_turu IN ('Yırtık', 'Islak', 'Yazı/Çizim', 'Eksik Sayfa', 'Kayıp')),
  aciklama VARCHAR(500),
  tespit_tarihi DATE NOT NULL DEFAULT (date('now')),
  tazminat_tutari DECIMAL(8,2) DEFAULT 0 CHECK (tazminat_tutari >= 0),
  FOREIGN KEY (kopya_id) REFERENCES Kitap_Kopyalari(kopya_id),
  FOREIGN KEY (odunc_id) REFERENCES Odunc_Islemleri(odunc_id),
  FOREIGN KEY (personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Cezalar (
  ceza_id INTEGER PRIMARY KEY AUTOINCREMENT,
  odunc_id INTEGER NOT NULL,
  hasar_id INTEGER,
  ceza_turu VARCHAR(15) NOT NULL CHECK (ceza_turu IN ('Gecikme', 'Hasar', 'Kayıp')),
  gecikme_gun INTEGER CHECK (gecikme_gun >= 0),
  toplam_tutar DECIMAL(8,2) NOT NULL CHECK (toplam_tutar >= 0),
  olusma_tarihi DATE NOT NULL DEFAULT (date('now')),
  odeme_durumu VARCHAR(15) DEFAULT 'Ödenmedi' CHECK (odeme_durumu IN ('Ödenmedi', 'Kısmi', 'Ödendi', 'Affedildi')),
  FOREIGN KEY (odunc_id) REFERENCES Odunc_Islemleri(odunc_id),
  FOREIGN KEY (hasar_id) REFERENCES Hasar_Kayitlari(hasar_id)
);

CREATE TABLE Ceza_Odemeleri (
  odeme_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ceza_id INTEGER NOT NULL,
  personel_id INTEGER,
  tutar DECIMAL(8,2) NOT NULL CHECK (tutar > 0),
  odeme_yontemi VARCHAR(15) CHECK (odeme_yontemi IN ('Nakit', 'Kart', 'Havale', 'Online')),
  makbuz_no VARCHAR(30) NOT NULL UNIQUE,
  odeme_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ceza_id) REFERENCES Cezalar(ceza_id),
  FOREIGN KEY (personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Calisma_Salonlari (
  salon_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sube_id INTEGER NOT NULL,
  salon_adi VARCHAR(80) NOT NULL,
  kat INTEGER,
  kapasite INTEGER NOT NULL CHECK (kapasite > 0),
  sessiz_mi BOOLEAN DEFAULT 1 CHECK (sessiz_mi IN (0,1)),
  grup_calismasi_mi BOOLEAN DEFAULT 0 CHECK (grup_calismasi_mi IN (0,1)),
  durum VARCHAR(15) DEFAULT 'Açık' CHECK (durum IN ('Açık', 'Bakımda')),
  UNIQUE (sube_id, salon_adi),
  FOREIGN KEY (sube_id) REFERENCES Subeler(sube_id)
);

CREATE TABLE Masalar (
  masa_id INTEGER PRIMARY KEY AUTOINCREMENT,
  salon_id INTEGER NOT NULL,
  masa_numarasi VARCHAR(10) NOT NULL,
  koltuk_sayisi INTEGER DEFAULT 1 CHECK (koltuk_sayisi > 0),
  priz_var_mi BOOLEAN DEFAULT 0 CHECK (priz_var_mi IN (0,1)),
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'Arızalı')),
  UNIQUE (salon_id, masa_numarasi),
  FOREIGN KEY (salon_id) REFERENCES Calisma_Salonlari(salon_id)
);

CREATE TABLE Masa_Rezervasyonlari (
  rezervasyon_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  masa_id INTEGER NOT NULL,
  baslangic_saati DATETIME NOT NULL,
  bitis_saati DATETIME NOT NULL,
  giris_zamani DATETIME,
  durum VARCHAR(15) DEFAULT 'Aktif' CHECK (durum IN ('Aktif', 'Giriş Yapıldı', 'Tamamlandı', 'İptal', 'Gelmedi')),
  CHECK (bitis_saati > baslangic_saati),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id),
  FOREIGN KEY (masa_id) REFERENCES Masalar(masa_id)
);

CREATE TABLE Etkinlikler (
  etkinlik_id INTEGER PRIMARY KEY AUTOINCREMENT,
  sube_id INTEGER NOT NULL,
  salon_id INTEGER,
  olusturan_personel_id INTEGER NOT NULL,
  baslik VARCHAR(150) NOT NULL,
  aciklama TEXT,
  baslangic_zamani DATETIME NOT NULL,
  bitis_zamani DATETIME NOT NULL,
  kontenjan INTEGER CHECK (kontenjan > 0),
  durum VARCHAR(15) DEFAULT 'Planlandı' CHECK (durum IN ('Planlandı', 'Tamamlandı', 'İptal')),
  CHECK (bitis_zamani > baslangic_zamani),
  FOREIGN KEY (sube_id) REFERENCES Subeler(sube_id),
  FOREIGN KEY (salon_id) REFERENCES Calisma_Salonlari(salon_id),
  FOREIGN KEY (olusturan_personel_id) REFERENCES Personel(personel_id)
);

CREATE TABLE Etkinlik_Katilimcilari (
  etkinlik_id INTEGER NOT NULL,
  uye_id INTEGER NOT NULL,
  kayit_zamani DATETIME DEFAULT CURRENT_TIMESTAMP,
  katildi_mi BOOLEAN DEFAULT 0 CHECK (katildi_mi IN (0,1)),
  PRIMARY KEY (etkinlik_id, uye_id),
  FOREIGN KEY (etkinlik_id) REFERENCES Etkinlikler(etkinlik_id),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id)
);

CREATE TABLE Okuma_Istatistikleri (
  istatistik_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  yil INTEGER NOT NULL,
  ay INTEGER NOT NULL,
  alinan_kitap_sayisi INTEGER DEFAULT 0 CHECK (alinan_kitap_sayisi >= 0),
  zamaninda_iade_sayisi INTEGER DEFAULT 0 CHECK (zamaninda_iade_sayisi >= 0),
  geciken_iade_sayisi INTEGER DEFAULT 0 CHECK (geciken_iade_sayisi >= 0),
  masa_kullanim_saati DECIMAL(6,2) DEFAULT 0 CHECK (masa_kullanim_saati >= 0),
  etkinlik_katilim_sayisi INTEGER DEFAULT 0 CHECK (etkinlik_katilim_sayisi >= 0),
  puan INTEGER DEFAULT 0,
  UNIQUE (uye_id, yil, ay),
  CHECK (ay BETWEEN 1 AND 12),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id)
);

CREATE TABLE Ayin_Odulleri (
  odul_id INTEGER PRIMARY KEY AUTOINCREMENT,
  uye_id INTEGER NOT NULL,
  istatistik_id INTEGER NOT NULL,
  odul_turu VARCHAR(40) NOT NULL CHECK (odul_turu IN ('Ayın Okuru', 'En Düzenli Üye', 'En Aktif Salon Kullanıcısı')),
  verilme_tarihi DATE NOT NULL,
  aciklama VARCHAR(255),
  UNIQUE (istatistik_id, odul_turu),
  FOREIGN KEY (uye_id) REFERENCES Uyeler(uye_id),
  FOREIGN KEY (istatistik_id) REFERENCES Okuma_Istatistikleri(istatistik_id)
);
