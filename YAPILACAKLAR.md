# C: Diskini Boşaltma ve Medal Kliplerini Google Drive'a Taşıma

Durum (SpaceSniffer'a göre): C: 793 GB, boş alan 88,7 GB.

| Yer | Boyut |
|---|---|
| `C:\Medal\Clips` | 299,5 GB (Counter-Strike 2: 277 GB, Valorant: 15 GB) |
| `C:\Medal\editor` | 13,7 GB |
| Steam | 157 GB |
| Riot Games | 42,7 GB |
| Downloads / Documents / Desktop | 27,6 / 27,6 / 17,1 GB |
| WinSxS | 24 GB |

Hedef: Klipler Medal uygulamasında görünmeye devam etsin ama dosyalar Google Drive'da dursun.

> Bu dosyayı bilgisayarınızda Claude Code ile açarsanız ona şunu diyebilirsiniz:
> "YAPILACAKLAR.md'deki adımları sırayla benimle birlikte uygula, her adımdan önce onay al."

---

## Adım 0: Ön kontroller

- [ ] Google Drive for Desktop kurulu ve oturum açık.
- [ ] Drive ayarı **"Dosyaları akışla aktar" (Stream files)** modunda.
      Kontrol etmek için: Drive simgesi → ⚙️ → Ayarlar → Google Drive.
      "Yansıt" (Mirror) modu seçiliyse yer kazanılmaz.
- [ ] Explorer'da `G:\Drive'ım` (veya `G:\My Drive`) klasörü görünüyor.
- [ ] Google hesabında yeterli boş alan var. 300 GB için **2 TB** plan gerekir.
      Önce 1. adımdaki temizliği yaparsanız daha küçük bir plan yetebilir.
      Kontrol için: https://one.google.com/storage

## Adım 1: Gereksiz klipleri silin (en çok zaman kazandıran adım)

Yüklenecek veri ne kadar azsa hem süre hem bulut alanı o kadar az harcanır.

- [ ] Medal → Library → Counter-Strike 2 → tarihe göre sıralayın. Saklamak istemediğiniz eski klipleri toplu silin.
- [ ] Aynısını Valorant ve diğer oyunlar için de yapın.
- [ ] `C:\Medal\editor\editor-active-drafts` (12,8 GB): gerek olmayan taslakları silin.
- [ ] Medal ayarlarında kayıt kalitesini (bitrate) düşürmeyi veya H.265/AV1 kodlamaya geçmeyi düşünün. Yeni klipler yaklaşık yarı boyutta olur.

## Adım 2: Script ile küçük bir test

Script: `Move-MedalClips.ps1` (bu depoda).

- [ ] Medal'ı **tamamen kapatın** (sistem tepsisinden → Quit).
- [ ] PowerShell'i proje klasöründe açın:
  ```powershell
  Set-ExecutionPolicy -Scope Process Bypass
  .\Move-MedalClips.ps1 -WhatIf
  ```
  Bu komut hiçbir şeyi taşımaz, yalnızca neyin nereye taşınacağını listeler. Kaynak ve hedef yolları kontrol edin.
- [ ] 2 GB'lık gerçek bir test yapın:
  ```powershell
  .\Move-MedalClips.ps1 -BatchGB 2
  ```

## Adım 3: Medal'ı yeni klasöre yönlendirin

- [ ] Medal'ı açın → Ayarlar → Recording / Storage → **Clip folder** ayarını değiştirin:
  `G:\Drive'ım\Medal\Clips`
- [ ] Taşınan test kliplerinin kütüphanede göründüğünü ve açıldığını kontrol edin.
      İlk açılış birkaç saniye sürebilir, çünkü dosya buluttan iniyor.
- [ ] **Klipler görünmüyorsa:** Durun. Medal'ın klip klasörünü `C:\Medal\Clips` olarak geri alın ve test dosyalarını G:'den geri taşıyın. Sonra başka bir yöntem düşünelim.

## Adım 4: Hepsini taşıyın

- [ ] Medal'ı kapatın.
- [ ] Scripti çalıştırın:
  ```powershell
  .\Move-MedalClips.ps1
  ```
  Script tek çalıştırmada en fazla 40 GB taşır. C: diskinde boş alan 30 GB'ın altına inecek olursa daha erken durur.
- [ ] Drive simgesinde yüklemenin bitmesini bekleyin ("Yedeklendi / Senkronize edildi" yazmalı).
- [ ] Komutu tekrar çalıştırın. "Kalan dosyalar var" mesajı çıkmayana kadar bunu tekrarlayın.

Süre tahmini: 20 Mbps upload hızıyla 100 GB yaklaşık 12 saat sürer.

## Adım 5: Yeni klipler için düzen

Adım 3'te Medal'ı G:'ye yönlendirdiyseniz yeni klipler doğrudan Drive'a kaydedilir.

- [ ] Birkaç gün boyunca yeni kliplerde takılma veya bozuk dosya olup olmadığını izleyin.
- [ ] **Sorun olursa:** Medal'ı yine `C:\Medal\Clips`'e kaydettirin. Haftada bir `.\Move-MedalClips.ps1 -OlderThanDays 7` komutuyla eski klipleri taşıyın.
      İsterseniz bu komutu Görev Zamanlayıcı (Task Scheduler) ile otomatik çalıştırabilirsiniz.

## Adım 6: Diğer temizlikler (isteğe bağlı, ~50+ GB)

- [ ] Oynamadığınız Steam ve Riot oyunlarını kaldırın.
- [ ] Downloads klasörünü boyuta göre sıralayıp eski kurulum dosyalarını silin.
- [ ] Önbellekleri temizleyin:
  ```powershell
  Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
  npm cache clean --force
  Remove-Item "$env:USERPROFILE\.gradle\caches" -Recurse -Force   # Android projesi kullanıyorsanız ilk derleme yeniden indirir
  ```
- [ ] Chrome'daki OptGuideOnDevice modeli (3,9 GB) için: `chrome://flags` → "Enables optimization guide on device" → **Disabled**.
- [ ] CapCut'ın ayarlarından önbelleği temizleyin (5,7 GB).
- [ ] Yönetici olarak açtığınız bir PowerShell'de:
  ```powershell
  DISM /Online /Cleanup-Image /StartComponentCleanup
  powercfg /h off   # uyku modunu (hibernate) kullanmıyorsanız
  ```

## Sorun giderme

| Sorun | Çözüm |
|---|---|
| "Medal açık" hatası | Sistem tepsisinden Medal → Quit. Görev Yöneticisi'nde Medal süreci kalmadığından emin olun. |
| "Google Drive klasörü bulunamadı" | `.\Move-MedalClips.ps1 -Destination "G:\...\Medal\Clips"` ile yolu elle verin. |
| "Hedefte zaten var, atlandı" | Dosya daha önce taşınmış. C:'deki kopyanın G:'de açıldığını kontrol edip C:'dekini silin. |
| C: yine doluyor | Drive önbelleğini başka bir diske taşıyın: Drive ayarları → "Yerel önbellek dosyaları dizini". |
| Script çalışmıyor | Hata çıktısını kopyalayıp Claude'a yapıştırın. |
