---
title: Stofna gæðaskoðun
audience: integrator
keywords: [quality, inspection, create]
locale: is-is
---

# Stofna gæðaskoðun

```json
{"type":"Quality.Inspection.Create","data":{"sourceTableId":39,"sourceSystemId":"00000000-0000-0000-0000-000000000001","templateCode":"RECEIPT"}}
```

`sourceTableId` er jákvæð heiltala og `sourceSystemId` er GUID-auðkenni einnar sýnilegrar færslu í núverandi fyrirtæki. `templateCode` er valfrjálst, má ekki vera tómt þegar það er gefið upp og má vera mest 20 stafir. Án þess velja stofnunarreglur Microsoft sniðmát. Óþekktum lyklum og ógildum auðkennum er hafnað fyrir stofnun.

Aðgerðin kallar á Create Inspection API frá Microsoft og `Qlty. Inspection - Create`. Valfrjálst sniðmát er sent með stöðluðum atburði; staðfestingar, upprunavarpanir, númeraraðir og verkflæðisatburðir eru áfram keyrð. Ekkert upprunaskjal er bókað og engin ytri þjónusta er kölluð.

Úthlutaðu `BIFROST QM Full ori` (innifalið í Foundation Full). Það inniheldur staðlaðar heimildir gæðaeftirlits Microsoft; kallandi þarf einnig viðeigandi heimildir að upprunafærslum. Foundation Read/API eitt og sér veitir ekki stofnunarheimild.

Svarið inniheldur `status`, `inspectionSystemId`, `inspectionNo`, `reinspectionNo` og `templateCode`. Stofnun er **ekki endurtekningarörugg**: endurtekin köll fylgja uppsetningu Microsoft sem getur endurnýtt skoðun eða stofnað nýja. Venjuleg færsla bakfærir allar breytingar við höfnun, einnig eftir innsetningu. Staðlaða leiðin inniheldur ekkert beint Commit; beinar staðfestingar frá áskrifendum eru bannaðar. Með Omit Commit ber kallandi ábyrgð á bakfærslu.

Settu upp gæðastjórnun, númeraraðir og upprunavarpanir fyrir notkun. Stofnunarreglur eru nauðsynlegar þegar templateCode er sleppt. Upprunafærsla sem vantar, ógilt sniðmát, uppsetning sem vantar eða ónógar heimildir skila skipulegri höfnun. Hjálp er aðgengileg í skilaboðaskrá og samnings-API Foundation.
