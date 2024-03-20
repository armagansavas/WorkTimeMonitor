# WorkTimeMonitor
#Task Schedule Command
w![TaskSchedule2](https://github.com/armagansavas/WorkTimeMonitor/assets/90199849/ba323ee1-d42c-4337-84f8-af2a9e2b66f0)
![TaskSchedule1](https://github.com/armagansavas/WorkTimeMonitor/assets/90199849/7e5ca559-f919-40de-adb4-bb5c2f6d7bca)
![TaskSchedule3](https://github.com/armagansavas/WorkTimeMonitor/assets/90199849/22871426-d5aa-40be-9eaf-355d19161ae2)
script "c:\temp\run_hidden.vbs" "C:\temp\ActivityTracker.ps1"



# PowerShell İzleyici ve Loglayıcı Scripti

Bu PowerShell scripti, bir bilgisayarın kullanıcı etkinliğini izler ve belirli bir süre boyunca aktif ve pasif zamanını hesaplar. Script, kullanıcı etkinliğini izlemek için Windows API'sini kullanır ve bir WMI sınıfı aracılığıyla toplanan verileri kaydeder.

## Ayarlar

- `$NewClassName`: WMI sınıfının adı.
- `$activeTime`: Aktif zamanı izlemek için kullanılan değişken.
- `$inactiveTime`: Pasif zamanı izlemek için kullanılan değişken.
- `$interval`: Kontrol aralığı (saniye cinsinden).
- `$targetDuration`: Toplam çalışma süresi hedef süresi (saniye cinsinden).
- `$passiveThreshold`: Pasif olarak kabul edilecek aralık (saniye cinsinden).

## WMI Sınıfının Oluşturulması

- Belirtilen ad ve özelliklere sahip bir WMI sınıfı oluşturur.

## Loglama Fonksiyonu (`Write-Log`)

- Hata, uyarı veya bilgi düzeylerinde loglama yapar.
- Log dosyasının boyutunu kontrol eder ve gerektiğinde yeniden oluşturur.
- Log dosyasına formatlanmış mesajı ekler.

## Kullanıcı Etkinliğinin İzlenmesi

- `UserInputInfo` sınıfı aracılığıyla kullanıcı etkinliğini izler.
- Kullanıcının etkin olup olmadığını belirler.
- Kullanıcının etkin olduğu süreyi ve pasif olduğu süreyi günceller.

## Ana Döngü

- Belirtilen hedef süreye ulaşılana kadar ana döngüde kalır.
- Her döngüde kullanıcı etkinliği güncellenir ve toplam süre hesaplanır.

## WMI Sınıfına Veri Gönderme ve Gösterme

- Toplam aktif ve pasif süreleri WMI sınıfına kaydeder.
- Kaydedilen verileri WMI sınıfından alır ve gösterir.

---

Bu script, bilgisayar kullanım izleme ve raporlama gibi senaryolar için kullanılabilir ve uygun bir şekilde yapılandırılarak işletim sistemi kullanımını izlemek için kullanılabilir.
