# Quality.Disposition.CreateTransferOrder

Stofnar millilagerfærslu(r) fyrir fallnar eða staðnar birgðir einnar skoðunar með stöðluðu ráðstöfunarviðmóti gæðastjórnunar Microsoft (`Create Transfer Order`), til dæmis til að senda fallnar birgðir á sóttkvíarstaðsetningu. Millilagerfærslan er stofnuð og skilin eftir opin: ekkert er sent, móttekið eða bókað. Svarið telur upp `transferOrderNos`.

Auðkenndu skoðunina, ásamt endurskoðun hennar, með `inspectionSystemId`. Sendu `quantityBasis` (`failed` eða `passed`), nauðsynlegt `destinationLocationCode` og `confirm=true`. Valfrjálst: `quantity` (tiltekið grunnmagn stærra en núll), nákvæmt `sourceLocationCode` (10 stafir) og `sourceBinCode` (20), `destinationBinCode` (20; millilagerfærslur Microsoft hafa ekki áfangahólf) og `inTransitLocationCode` (10). Síusetningafræði í staðsetningar- eða hólfskóðum er hafnað. Án staðsetningar á leiðinni notar Microsoft flutningsleiðina milli staðsetninganna, annars er flutningurinn beinn.

```json
{"type":"Quality.Disposition.CreateTransferOrder","data":{"inspectionSystemId":"<inspection-SystemId>","quantityBasis":"failed","destinationLocationCode":"QUARANTINE","confirm":true,"expectedCount":1}}
```

Kallandi þarf `BIFROST QM Full ori` og staðlaðar heimildir Microsoft fyrir millilagerfærslur; lestrarhlutverk og grunnhlutverk er hafnað. Höfnun frá Microsoft (uppsetning, staðsetningar, hólf) eða seinbúin villa bakfærir allt sem kallið gerði. Með `Omit Commit` ber kallandi viðbót ábyrgð á færslunni.

Þetta er **ekki ídempótent**. Endurtekin heppnuð beiðni getur stofnað aðra millilagerfærslu. Ekki endurtaka heppnaða beiðni sjálfvirkt. Engin skilaboðategund til að eyða eða hætta við er til; fjarlægðu óæskilega millilagerfærslu í Business Central.

Foundation beitir staðlaðri forskoðun óafturkræfra aðgerða: sendu `expectedCount=1` fyrir skoðunina (ekki fjölda millilagerfærslna). Fjölda sem er ekki 1 er hafnað áður en nokkru er breytt; ef honum er sleppt er fjöldinn lesinn og engu breytt meðan Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt.

Höfnun er tegundarbundin (`code`, `parameter`, `expected`, `nextStep`): `MissingParameter` fyrir vantandi eða ógilt `inspectionSystemId` eða vantandi `destinationLocationCode`, `InvalidParameter` fyrir `confirm`, síusetningafræði, magn eða grunn, `UnknownParameter`, `RecordNotFound` fyrir óþekkta skoðun og `PreconditionFailed` þegar magn skoðunar er núll.
