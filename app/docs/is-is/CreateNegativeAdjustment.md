# Quality.Disposition.CreateNegativeAdjustment

Afskrifar fallið eða staðist magn tiltekinnar skoðunar með neikvæðri birgðaleiðréttingu í gegnum staðlað ráðstöfunarviðmót gæðastjórnunar Microsoft (`Dispose with Negative Inventory Adjustment`). Leiðréttingarlínurnar eru stofnaðar í vörufærslubókarbunkanum sem uppsetning gæðastjórnunar tilgreinir. Þær eru þar áfram nema `postImmediately=true`, sem bókar þær og lækkar birgðir.

Auðkenndu nákvæma skoðun, ásamt endurskoðun hennar, með `inspectionSystemId`. Sendu `quantityBasis` (`failed` eða `passed`) og `confirm=true`. Valkvætt: `quantity` (grunnmagn hærra en núll sem er afskrifað í stað alls magns viðmiðsins), nákvæm `sourceLocationCode` (10 stafir) og `sourceBinCode` (20) án síunarsetningafræði, `reasonCode` (10 stafir) og `postImmediately` (sjálfgefið `false`, aðeins undirbúið).

```json
{"type":"Quality.Disposition.CreateNegativeAdjustment","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","reasonCode":"SCRAP","postImmediately":false,"confirm":true,"expectedCount":1}}
```

Svarið segir hvort línurnar voru bókaðar (`posted`), telur upp færslubókarlínur sem eru eftir í færslubók (`journalLines`) og vörufærslurnar sem voru skrifaðar (`ledgerEntries`).

Kallandi þarf `BIFROST QM Full ori` og staðlaðar heimildir Microsoft fyrir vörufærslubók og bókun. Lestrarhlutverkinu og grunnhlutverkum er hafnað.

Aðgerðin er **ekki ídempótent**. Bókaðar færslur breyta birgðum og endurtekin beiðni getur afskrifað meira magn. Endurtekning tvöfaldar einnig undirbúnar línur. Engin eyðingargerð og engin „bakfæra leiðréttingu“ gerð er til. Ekki endurtaka heppnaða beiðni sjálfkrafa.

Staðlað bókun Microsoft keyrir með bældar staðfestingar og bannaðar beinar staðfestingar. Höfnun, til dæmis vantar færslubókarbunka, sniðmát krefst bókunarskýrslu, birgðir duga ekki eða seint bilun, bakfærir línur og bókun saman. Staðsetningar með stýrða vörslu og tínslu nota vöruhúsafærslubók; þar er aðeins stutt að undirbúa. Með `Omit Commit` ber kallandi viðbót ábyrgð á færslunni.

Foundation notar einnig staðlaða forskoðun óafturkræfra aðgerða: sendu `expectedCount=1` fyrir eina skoðun. Fjölda sem er ekki 1 er hafnað áður en nokkru er breytt. Þetta kemur ekki í stað `confirm=true`.

Sérhver höfnun áður en staðlaða ráðstöfunin keyrir er týpuð með `parameter`, `expected` og `nextStep`: `inspectionSystemId` vantar eða er gallað, `confirm` er ekki true, óþekktir lyklar, síunarsetningafræði, óþekkt skoðun, núllmagn og ástæðukóði lengri en 10 stafir.
