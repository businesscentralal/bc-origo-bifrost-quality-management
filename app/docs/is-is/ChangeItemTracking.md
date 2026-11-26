# Quality.Disposition.ChangeItemTracking

Breytir lotu-, rað- eða pakkanúmeri, eða fyrningardagsetningu, fallins eða staðins magns einnar skoðunar með staðlaðri gæðaráðstöfun Microsoft (`Change Item Tracking`, kóðaeining `Qlty. Disp. Change Tracking`). Stofnar endurflokkunarlínu vöru, eða endurflokkunarlínu vöruhúss í birgðageymslu með stýrðri frágangi og tínslu, í bunkanum sem er tilgreindur í uppsetningu gæðastjórnunar. `postImmediately=true` bókar hana í sama kalli.

Auðkenndu nákvæma skoðun, ásamt endurskoðun hennar, með `inspectionSystemId`. Skoðunin verður að tilgreina lotu-, rað- eða pakkanúmer; þessi tegund bætir ekki rakningu við birgðir án rakningar. Sendu að minnsta kosti eitt af `newLotNo`, `newSerialNo`, `newPackageNo` (hvert allt að 50 stafir) eða `newExpirationDate` (`YYYY-MM-DD`), ásamt `quantityBasis` (`failed` eða `passed`) og `confirm=true`. Valfrjálst `quantity` (jákvætt magn í grunneiningu) breytir minna en grunnmagninu. Valfrjálsir nákvæmir kóðar `sourceLocationCode` (10 stafir) og `sourceBinCode` (20) takmarka staðlað val uppruna; síusegðum er hafnað. Sjálfgefið gildi `postImmediately` er false (aðeins undirbúið).

```json
{"type":"Quality.Disposition.ChangeItemTracking","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","newLotNo":"LOT-QA-01","confirm":true,"expectedCount":1}}
```

Svarið tilgreinir `posted` og telur upp það sem kallið stofnaði: `journalLines` (með núverandi og nýju lotu-, rað- og pakkanúmeri og nýrri fyrningardagsetningu), `warehouseJournalLines`, og eftir bókun `ledgerEntries` (millifærslufærslur út og inn) og `warehouseEntries`.

Höfnun áður en nokkru er breytt skilar villum af tiltekinni gerð með `parameter`, `expected` og `nextStep`: ekkert nýtt gildi, gildi lengra en 50 stafir, ranglega sniðin dagsetning, `inspectionSystemId` sem vantar eða er ranglega sniðið, `confirm` ekki true, óþekktir lyklar, síusegðir, óþekkt skoðun, skoðun án rakningar og magn núll. Höfnun Microsoft (endurflokkunarbunka vantar, ónógar birgðir, eða ný fyrningardagsetning fyrir aðeins hluta lotu: Microsoft breytir dagsetningu lotu aðeins fyrir allt eftirstandandi magn hennar) og síðbúin villa skilja hvorki eftir línur né færslur.

Kallandi þarf `BIFROST QM Full ori` og staðlaðar heimildir Microsoft fyrir vörubók, vörurakningu og bókun; engar heimildir Microsoft eru auknar. Les- og grunnhlutverkum er hafnað.

Þetta er **ekki ídempótent**. Bókaðar færslur breyta auðkenni birgða og endurtekin beiðni afturkallar þær ekki; endurtekin beiðni breytir birgðum aftur. Engin eyðingartegund og engin afturköllunartegund er til.

Venjuleg gæðabókun Microsoft staðfestir á undan einstökum línum. Umbúðirnar binda staðlaða bókun með bælingu staðfestinga og banna beinar staðfestingar, svo höfnun bakfærir stofnun lína og bókun saman. Með `Omit Commit` ber kallandi viðbót ábyrgð á færslunni. Engu prufu-, leyfis-, samþykkis- eða ytri þjónustuástandi er breytt.

Foundation beitir forskoðun óafturkræfra aðgerða: `expectedCount` telur eina skoðun (sendu `1`). Öðru gildi er hafnað áður en nokkru er breytt. Þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt í Uppsetningu Bifröst (virkt sjálfgefið) les það að sleppa `expectedCount` fjöldann og breytir engu. Þetta kemur ekki í stað `confirm=true`.
