# Quality.Disposition.MoveInventory

Flytur fallið eða staðist magn tiltekinnar skoðunar með stöðluðu ráðstöfunarviðmóti gæðastjórnunar Microsoft. Stofnar endurflokkunarlínur vöru eða vöruhúss, innri flutninga eða línur vinnublaðs flutnings. `postImmediately=true` bókar endurflokkun strax. Vinnublað og innri flutningur undirbúa eingöngu.

Auðkenndu nákvæma skoðun, ásamt endurskoðun hennar, með `inspectionSystemId`. Sendu `quantityBasis` (`failed` eða `passed`), `method` (`automatic`, `itemReclassification`, `warehouseReclassification`, `movementWorksheet`, `internalMovement`), birgðageymslu og/eða hólf á áfangastað og `confirm=true`. Valfrjálsir nákvæmir kóðar `sourceLocationCode` (10 stafir) og `sourceBinCode` (20) takmarka staðlað val uppruna; síusegðum er hafnað. Mörk áfangastaðar eru 10 og 20 stafir. Óþekktum lyklum, ranglega sniðnum gildum og færibreytum sem vantar er hafnað áður en flutningur hefst. Sjálfgefið gildi `postImmediately` er false.

Kallandi þarf `BIFROST QM Full ori` og staðlaðar heimildir Microsoft fyrir valda birgðaaðgerð. Full hlutverkið inniheldur heimildir Microsoft `QltyMgmt - Inspector`; aðrar birgðaheimildir eru ekki auknar. Microsoft staðfestir birgðir, geymslur, hólf og uppsetningu flutnings. Staðist eða fallið magn skoðunar verður að vera jákvætt. Hjálparsamningurinn lýsir nákvæmum svarreitum.

Aðgerðin er **ekki ídempótent**. Endurtekið heppnað kall getur stofnað annan flutning. Ekki endurtaka sjálfkrafa heppnaða beiðni. Bókaðar færslur hafa áhrif á birgðir og endurtekin beiðni afturkallar þær ekki.

Venjuleg gæðabókun Microsoft staðfestir fyrir hverja línu. Viðbótin bindur staðlaða bókun vöru eða vöruhúss með bældri staðfestingu og bannar beinar staðfestingar meðan ráðstöfun stendur. Viðskiptahöfnun bakfærir stofnun lína og bókun saman. Venjuleg heppnuð keyrsla staðfestir einangraða færslu einu sinni. Með `Omit Commit` ber kallandi viðbót ábyrgð á færslu og bakfærslu. Engu ástandi prufu, leyfis, samþykkis eða ytri þjónustu er breytt.

Foundation notar einnig staðlaða forskoðun óafturkræfra aðgerða: sendu `expectedCount=1` fyrir eina skoðun. Röngum fjölda er hafnað áður en flutningur hefst. Þetta kemur ekki í stað `confirm=true`.
