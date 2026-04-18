# gecit

Upstream `gecit` DPI bypass engine’i için native macOS masaüstü istemcisi ve UI katmanı.

Bu fork, orijinal cross-platform runtime engine’i korur ve onun üstüne ürünleşmiş bir macOS deneyimi ekler: onboarding, helper kurulumu, menu bar kontrolleri, ayar arayüzü ve log görüntüleme. Paket içindeki `gecit` binary’si Swift içinde yeniden yazılmaz; yönetilen bir subprocess/helper olarak çalıştırılır.

## Bu repo ne?

Bu repoda iki katman vardır:

1. **Upstream runtime engine** — orijinal `gecit` CLI ve ağ implementasyonu
2. **macOS app istemcisi** — paket içindeki runtime’ı kuran, yapılandıran, başlatan, durduran ve izleyen native Swift menu bar app

Yalnızca alttaki engine’i kullanmak istiyorsanız CLI ile devam edebilirsiniz.
macOS’ta düzgün bir ürün deneyimi istiyorsanız `apps/macos` altındaki native app’i kullanın.

## macOS app tam olarak ne yapıyor?

macOS app ayrı bir DPI engine değildir. Paket içindeki `gecit-darwin-arm64` binary’si için native bir kontrol düzlemidir.

Şunları sağlar:

- ilk açılış onboarding akışı
- yetkili helper kurulumu
- menu bar popover arayüzü
- start / stop / cleanup kontrolleri
- TTL / DoH / interface / ports ayarları
- runtime durum ve son loglar

Çalışma anında app, helper’ı `/Library/Application Support/Gecit` altına kurar, paketli binary’yi çalıştırır ve kontrol/durum bilgisini paylaşılan dosyalar üzerinden yönetir.

## Repo yapısı

- `cmd/gecit` — upstream CLI giriş noktası
- `pkg/` — upstream networking, TUN, fake packet injection, DNS, capture, raw socket ve platform kodları
- `apps/macos` — native Swift macOS app
- `bin/` — derlenen binary’ler

## Hangi giriş noktasını kullanmalıyım?

### Seçenek 1: CLI’yi doğrudan kullan

```bash
sudo gecit run
```

CLI/runtime davranışı upstream projeyle aynıdır:

- **Linux**: eBPF sock_ops, proxy yok, trafik yönlendirme yok
- **macOS/Windows**: TUN tabanlı şeffaf proxy
- dahili DoH DNS resolver
- DPI desync için sahte TLS ClientHello enjeksiyonu

### Seçenek 2: Native macOS app’i kullan

`apps/macos` altındaki Xcode projesini açın, app’i build edin ve onboarding akışını native UI içinden tamamlayın.

Bu app helper’ı bir kez kurar, ardından runtime’ı menü çubuğu arayüzünden yönetmenizi sağlar; CLI komutlarını elle çalıştırmanız gerekmez.

App’e özel detaylar için [apps/macos/README.md](apps/macos/README.md) dosyasına bakın.

## Alttaki engine nasıl çalışıyor?

```
Uygulama hedef:443'e bağlanır
    ↓
gecit bağlantıyı yakalar
  Linux:  eBPF sock_ops tetiklenir
  macOS/Windows: TUN cihazı paketi yakalar, gVisor netstack TCP'yi sonlandırır
    ↓
Düşük TTL ile sahte ClientHello gönderilir (SNI: "www.google.com")
    ↓
Sahte paket DPI'a ulaşır → DPI zararsız SNI görür → bağlantıya izin verir
Sahte paket sunucuya ulaşmadan ölür → sunucu görmez
    ↓
Gerçek ClientHello geçer → DPI zaten desync olmuştur
```

Bazı ISP'ler TLS ClientHello içindeki SNI alanını okuyarak belirli alan adlarını engeller. `gecit`, gerçek ClientHello’dan önce farklı bir SNI ve düşük TTL ile sahte ClientHello gönderir. DPI sahte paketi işler, fakat paket düşük TTL nedeniyle sunucuya ulaşmadan yok olur.

Engine ayrıca DNS zehirlemesini aşmak için dahili DoH DNS resolver içerir.

## Gereksinimler

| | Linux | macOS | Windows |
|---|---|---|---|
| **İşletim Sistemi** | Kernel 5.10+ | macOS 12+ | Windows 10+ |
| **Yetki** | root / sudo | root / sudo | Yönetici |
| **Bağımlılık** | Yok | Yok | [Npcap](https://npcap.com) |

## Derleme

### Runtime binary’lerini derle

```bash
make gecit-linux-amd64
make gecit-linux-arm64
make gecit-darwin-arm64
make gecit-darwin-amd64
make gecit-windows-amd64
```

### macOS app’i derle

```text
apps/macos/geçit.xcodeproj
```

macOS app kurulum sırasında paket içindeki runtime binary’sini sisteme kurmayı bekler.

## CLI kullanımı

```bash
# Varsayılan
sudo gecit run

# Google DoH kullan
sudo gecit run --doh-upstream google

# Birden fazla upstream
sudo gecit run --doh-upstream cloudflare,quad9

# Özel DoH URL
sudo gecit run --doh-upstream https://8.8.8.8/dns-query

# Özel TTL
sudo gecit run --fake-ttl 12

# Sistem yeteneklerini kontrol et
sudo gecit status

# Çökme sonrası sistem ayarlarını geri yükle
sudo gecit cleanup
```

## CLI parametreleri

| Parametre | Varsayılan | Açıklama |
|-----------|-----------|----------|
| `--doh-upstream` | `cloudflare` | DoH upstream hazır adı veya URL; virgülle fallback verilebilir |
| `--fake-ttl` | `8` | Sahte paket TTL değeri |
| `--mss` | `40` | Linux’ta ClientHello fragmentasyonu için TCP MSS |
| `--ports` | `443` | Hedef portlar |
| `--interface` | otomatik | Ağ arayüzü |
| `-v` | kapalı | Ayrıntılı loglama |

## Platform farkları

| | Linux | macOS | Windows |
|---|---|---|---|
| **Motor** | eBPF sock_ops | TUN + gVisor netstack | TUN + gVisor netstack |
| **Sahte enjeksiyon** | Raw socket | Raw socket | Npcap ile raw socket |
| **DNS bypass** | DoH + `/etc/resolv.conf` | DoH + `networksetup` | DoH + `netsh` |
| **Root gerekli** | Evet | Evet | Evet |

## SSS

**Bu repo artık esasen bir macOS app mi?**
Evet. Bu fork’un ana farklılaştırıcı tarafı native macOS istemci deneyimi. Upstream CLI/runtime hâlâ repoda duruyor ve gerçek ağ işini o yapıyor.

**macOS app runtime engine’in yerini alıyor mu?**
Hayır. App, paket içindeki binary’yi subprocess/helper olarak yönetir.

**Bu bir VPN mi?**
Hayır. Uzak tünel veya anonimlik katmanı yoktur. Trafik doğrudan internete çıkar.

**IP adresimi gizler mi?**
Hayır. Yalnızca DPI ve DNS tabanlı engelleme davranışlarını hedefler.

## Lisans

GPL-3.0. Detaylar için [LICENSE](LICENSE).

Telif Hakkı (c) 2026 Bora Tanrikulu <me@bora.sh>
