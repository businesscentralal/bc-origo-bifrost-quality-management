# Finna skoðanir fyrir upprunafærslu

```json
{
  "type": "Quality.Inspection.FindForRecord",
  "data": {
    "tableId": 39,
    "systemId": "00000000-0000-0000-0000-000000000001",
    "matchOn": [
      "document"
    ],
    "latestOnly": true
  }
}
```

Skilar allt að 100 skoðunum með opinberu aðferðinni `SetRecordFiltersToFindInspectionFor` frá Microsoft. Kallið stofnar aldrei skoðun eða breytir henni.

| Inntak | Merking |
| --- | --- |
| `tableId` | Nauðsynlegt jákvætt heiltöluauðkenni upprunatöflu í núverandi fyrirtæki. |
| `systemId` | Nauðsynlegt ótómt GUID-auðkenni sýnilegrar upprunafærslu. |
| `matchOn` | Nauðsynlegt ótómt fylki með `item`, `tracking`, `document`. Valdar síur eru sameinaðar með staðlaðri upprunauppsetningu. |
| `latestOnly` | Valfrjálst rökgildi, sjálfgefið `true`. Velur nýjustu endurskoðun hverrar skoðunar; `false` tekur eldri útgáfur með. |

Svarið inniheldur `status: Success`, fylkið `inspections` og `truncated`. Hver skoðun inniheldur `inspectionSystemId`, `no`, `reinspectionNo`, `status` (enskt heiti talningargildis) og `result` (staðlaðan niðurstöðukóða). Röðun er eftir stofnunartíma í lækkandi röð, síðan skoðunarnúmeri og endurskoðunarnúmeri í lækkandi röð. Að hámarki eru 100 sýnilegar línur í svari; `truncated` er aðeins true þegar fleiri línur passa. Engin samsvörun skilar tómu fylki.

Notaðu leshlutverk Foundation, `BIFROST QM Read ori` (fylgir leshlutverki Foundation) og staðlaðar lesheimildir á upprunafærslu og `Qlty. Inspection Header`. Fullur aðgangur er ekki nauðsynlegur. Stöðluð upprunauppsetning verður að varpa öllum völdum samsvörunargildum. Engin skrifstaðfesting er samþykkt eða nauðsynleg.

Ef nauðsynlega lykla vantar er skilað `MissingParameter`; gölluð auðkenni, óþekktar töflur, ógilt `matchOn`, upprunagildi sem vantar eða ógild rökgildi skila `InvalidParameter`; óþekktur lykill skilar `UnknownParameter`. Inntak er staðfest áður en skoðanir eru lesnar. Óþekkt upprunafærsla skilar `RecordNotFound`; ef staðlaðar lesheimildir vantar er skilað `PermissionDenied`. Hver höfnun inniheldur `parameter`, `expected` og `nextStep`.
