---
title: Setja stofnunarreglur á tímaáætlun
description: Stofna eitt endurtekið verk fyrir gæðaskoðanir með skýrri virkjun.
---

# Setja stofnunarreglur á tímaáætlun

```json
{"type":"Quality.GenerationRule.Schedule","data":{"scheduleGroup":"QM","startTime":"08:00:00","daysOfWeek":[1,2,3,4,5],"repeatEveryMinutes":60,"activate":false,"expectedCount":1}}
```

Þessi skrifaðgerð stjórnanda stofnar eina staðlaða verkbiðraðarfærslu fyrir Microsoft-skýrsluna `Qlty. Schedule Inspection`. Kallið keyrir ekki skýrsluna og stofnar engar skoðanir. Verkið byrjar **í bið** (`On Hold`). Stilltu `activate: true` til að gera það **tilbúið** (`Ready`) með staðlaðri tímaáætlun; framtíðarkeyrslur geta þá stofnað skoðanir.

| Viðfang | Snið og sjálfgefið gildi |
| --- | --- |
| `scheduleGroup` | Kóði með 1–20 stöfum; sjálfgefið `QM`. Stöðluð samræming kóða gildir. |
| `startTime` | Áskilið `HH:mm:ss`, `00:00:00`–`23:59:59`, í tímabelti notandans sem áætlar verkið; varpað á upphafstíma. Miðnætti notar staðlað `0T`. |
| `daysOfWeek` | Fylki sem er ekki tómt með einkvæmum heiltölum, 1=mánudagur til 7=sunnudagur. Sjálfgefið allir sjö dagarnir. Varpað á sjö vikudagareiti. |
| `repeatEveryMinutes` | Heiltala 1–2147483647; sjálfgefið 1440 (daglega). Varpað á fjölda mínútna milli keyrslna. |
| `activate` | JSON-rökgildi; sjálfgefið false. |
| `expectedCount` | Ein verkbiðraðarfærsla, **ekki framtíðarskoðanir**. Sent gildi verður að vera 1. |

Þegar **Krefjast staðfestingar fyrir óafturkræf skilaboð** er virkt í Bifröst uppsetningu má sleppa `expectedCount` til að lesa `expected: "1"` í `ConfirmationRequired` svari án breytinga. Sendu sömu beiðni aftur með `expectedCount: 1`. Þegar stillingin er óvirk leyfir vöntun stofnun; sendur fjöldi er alltaf athugaður. Yfirlýst áhrif eru `write`.

Svarið inniheldur `status: "Success"`, `noOfRecords: 1`, `jobQueueEntryId` (GUID), `jobStatus` (`On Hold` eða `Ready`), `scheduleGroup` og óstaðfært upptalningarheiti í `inspectionCreationOption`. Þýdd `warning` fylgir fyrir **Always create new inspection** og **Always create re-inspection**, því þessar stillingar geta stofnað skoðanir við hverja keyrslu þótt skoðanir séu þegar til.

Fyrir stofnun verður flokkurinn að innihalda að minnsta kosti eina stofnunarreglu og **hver regla** verður að hafa skilyrðis-, vöru- eða vörueiginleikasíu, einnig óvirkar reglur. Reglur eða uppsetningu vantar, reglur án síu og fyrirliggjandi skýrsluverk sem ná yfir flokkinn skila `PreconditionFailed`. Verk sem eru stofnuð í staðlaða viðmótinu finnast einnig. Ólæsileg skýrsluviðföng hindra stofnun til öryggis; farðu yfir þau á Verkbiðraðarfærslum. Óþekktir lyklar, rangar JSON-gagnagerðir, of langir eða tómir flokkar, ógildir tímar/dagar og mörk endurtekningar skila flokkuðum höfnunum með `parameter`, `expected` og `nextStep`. Engin höfnun breytir verkbiðröðinni.

Úthlutaðu `BIFROST QM Full ori` (fylgir einnig Foundation Full) og Foundation API hlutverki. Full-hlutverkið veitir sérstaka tímaáætlunarheimild og staðlaðar verkbiðraðarheimildir. Grunn- og leshlutverk geta ekki áætlað verk. Staðlaðar heimildir gilda áfram um framtíðarkeyrslu skýrslunnar. Engum reglum eða uppsetningu er breytt. Breyttu fyrirliggjandi verki á **Verkbiðraðarfærslum**; þessi skilaboð skipta aldrei út, eyða, setja í bið eða keyra fyrirliggjandi verk.

Stofnun og virkjun deila einni færslu. Árangur staðfestir einu sinni; staðlað villa afturkallar öll skrif. Í Omit Commit ham á kallandi færsluna. Aðgerðin er ekki ítrekunarörugg: endurtekið kall eftir árangur fær höfnun vegna tvítekningar.

Útfærslan notar opinbera BC 28 hluti og staðlað XML fyrir skýrsluviðföng. Innri hjálparaðgerðir Microsoft eru hvorki kallaðar né afritaðar. Engar síður, aðgerðir eða hjálparslóðir breytast.
