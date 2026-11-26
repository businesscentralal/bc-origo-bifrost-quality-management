---
title: Quality.Report.Print
audience: developer, admin
keywords: gæði, skýrsla, greiningarvottorð, frávik, pdf
locale: is-is
---

```json
{"type":"Quality.Report.Print","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","report":"certificateOfAnalysis","languageCode":"is-IS"}}
```

Býr til eina af skýrslum Microsoft í gæðastjórnun fyrir eina skoðun sem PDF og skilar henni í gegnum biðsvæði Foundation. Aðgerðin breytir engum viðskiptagögnum; eina skrifið er biðsvæðisfærsla Foundation sem er vinnugögn.

| Lykill | Áskilinn | Gildi |
| --- | --- | --- |
| `inspectionSystemId` | já | SystemId skoðunarinnar |
| `report` | já | `certificateOfAnalysis` (greiningarvottorð), `nonConformance` (frávikaskýrsla) eða `general` (almenn skoðunarskýrsla) |
| `languageCode` | nei | `en-US` eða `is-IS`; tungumál lotunnar er endurheimt eftir myndun, einnig eftir höfnun |

Niðurstaða: `stagingId` PDF-skjalsins, `fileName` (skoðunarnúmer, endurskoðunarnúmer og skýrsla), `contentType` (`application/pdf`) og `sizeBytes`. Lestu PDF-skjalið með núverandi biðsvæðistegundum með `stagingId`.

Hafnað áður en skýrsla er búin til með tegundaðri villu: `inspectionSystemId` sem vantar eða er rangt, `report` sem vantar eða er óþekkt, óþekkt `languageCode`, óþekktir lyklar og skoðun sem er ekki til (`RecordNotFound`). Niðurstöðu yfir 10.485.760 bætum er hafnað með `LimitExceeded`, hún er ekki stytt og engin biðsvæðisfærsla verður eftir. Því sem skýrslan sjálf hafnar er skilað sem `BusinessCentralError`.

Heimildir: úthlutaðu `BIFROST QM Read ori` með lesheimildum Microsoft í gæðastjórnun (`QltyMgmt - Read`) og grunnlesaðgangi að fyrirtækjaupplýsingum sem skýrslurnar nota. Kallandi án lesaðgangs að skoðuninni eða keyrsluheimildar fyrir skýrsluna fær `PermissionDenied`.

Skýrsla Microsoft er búin til með sjálfgefnu útliti. Sérsniðin færsla í Report Selections er ekki notuð. Engin ytri þjónusta er kölluð.
