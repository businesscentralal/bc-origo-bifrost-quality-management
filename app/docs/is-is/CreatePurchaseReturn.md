# Quality.Disposition.CreatePurchaseReturn

```json
{"type":"Quality.Disposition.CreatePurchaseReturn","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001","reasonCode":"QUALITY","vendorCreditMemoNo":"VC-001"}}
```

Stofnar **óbókaða innkaupaskilapöntun** fyrir fallið magn skoðunar með `Qlty. Disp. Purchase Return` frá Microsoft. Uppruni verður að vera innkaupalína með jákvætt fallið magn, nægt móttekið magn og gilda innkaupauppsetningu. Krefst `BIFROST QM Full ori` og innkaupaheimilda. `reasonCode` (10 stafir) og `vendorCreditMemoNo` (35 stafir) eru valfrjálsir textar. Óþekktir, ógildir og vantaðir lyklar ásamt viðskiptahöfnunum breyta engu. Bókar ekki kreditreikning. **Ekki ítrekunaröruggt:** endurtekning getur stofnað aðra skilapöntun. Staðlaða leiðin inniheldur ekkert beint Commit; beinar staðfestingar frá áskrifendum eru bannaðar. Venjuleg keyrsla bakfærir við höfnun; með Omit Commit ber kallandi ábyrgð á bakfærslu.

```json
{"status":"Success","inspectionSystemId":"00000000-0000-0000-0000-000000000001","returnOrderNo":"PRO00001"}
```

| Kóði | Færibreyta | Úrbætur |
| --- | --- | --- |
| `MissingParameter` | `inspectionSystemId` | Sendu SystemId skoðunar sem er ekki tómt. |
| `RecordNotFound` | `inspectionSystemId` | Lestu skoðun sem er til; `received` endurtekur óþekkta GUID gildið. |
| `InvalidParameter` | Ógilt GUID eða valfrjáls texti | Leiðréttu snið eða lengd. |
| `PermissionDenied` | `permissionSet` | Biddu um tilgreindar app- og staðlaðar heimildir. |
| `PreconditionFailed` | `inspectionSystemId` | Veldu innkaupaskoðun og athugaðu uppsetningu og áskrifendur ráðstöfunar. |

Hver höfnun úr eigin athugunum inniheldur `parameter`, `expected` og `nextStep`. Staðlaðar sannprófanir Business Central halda sinni villuflokkun. Höfnun eftir skrif bakfærir skilapöntunina.
