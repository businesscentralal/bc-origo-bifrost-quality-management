---
title: Quality.Inspection.SetTestValue
audience: developer, admin
keywords: quality, inspection, test, result
locale: is-is
---

```json
{"type":"Quality.Inspection.SetTestValue","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","testCode":"TEMP","value":"20"}}
```

Staðfestir eitt prófunargildi í opinni gæðaskoðun og endurreiknar heildarniðurstöðu hennar með aðferðunum `SetTestValue` og `UpdateResultFromLines` frá Microsoft.

| Nauðsynlegur lykill | Gildi |
| --- | --- |
| `inspectionSystemId` | SystemId tiltekinnar skoðunar og endurskoðunar |
| `testCode` | Prófunarkóði, hámark 20 stafir; nákvæmlega ein lína verður að samsvara |
| `value` | Texti, hámark 250 stafir; tómur texti hreinsar gildið ef Microsoft leyfir |

Óþekktum lyklum, lyklum sem vantar, öðrum gildum en texta, ógildum auðkennum og of löngum gildum er hafnað áður en skrifað er. Microsoft hafnar loknum skoðunum, prófunum sem vantar eða eru tvíteknar, ógildum gildum og uppsetningu sem vantar. Höfnun skilar `status: Error`. Venjuleg keyrsla bakfærir breytingar á línum og haus saman. Með `Omit Commit` ber kallandi ábyrgð á bakfærslu. Staðlaða leiðin inniheldur ekkert beint `Commit` og beinar staðfestingar í áskrifendum eru bannaðar.

Árangur skilar `status`, `inspectionSystemId`, `inspectionNo`, `reinspectionNo`, `testCode` og `resultCode`. Línugildi, tengdar segðir og niðurstaða hauss geta breyst; kveikjur og áskrifendur Microsoft keyra. Endurtekning sama gildis **tryggir ekki óbreytt ástand**. Úthlutaðu `BIFROST QM Full ori` ásamt viðeigandi Foundation vinnsluhlutverki; Full-safnið inniheldur skoðunarheimildir Microsoft. Read- og grunnsöfnin geta ekki keyrt aðgerðina. Engin ytri þjónusta er kölluð.

Notaðu `Data.Records.Get` í Foundation fyrir venjulegan lestur. Beint `Data.Records.Set` jafngildir ekki staðfestingu og endurreikningi niðurstöðu með þessari aðgerð.
