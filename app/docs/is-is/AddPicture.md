# Quality.Inspection.AddPicture

```json
{
  "type": "Quality.Inspection.AddPicture",
  "data": {
    "inspectionSystemId": "<SystemId-skoðunar>",
    "stagingId": "<SystemId-eigin-upphleðslu>",
    "fileName": "skodunarmynd",
    "expectedCount": 1
  }
}
```

Skiptir út **nýjustu mynd** einnar opinnar gæðaskoðunar. Sendu nákvæmlega annað af
`base64` (kóðuð myndbæti) og `stagingId` (Foundation-upphleðsla í eigu núverandi notanda
í núverandi fyrirtæki). JPEG, PNG og BMP eru leyfð. Myndafkóðari staðfestir bætin;
rangt skráarheiti eða MIME-gildi leyfir ekki annað snið.
Hámarksstærð afkóðaðrar myndar er **1 MiB (1048576 bæti)**. Mynd nákvæmlega við mörkin er leyfð.
Hámark base64-texta er 1398104 stafir áður en afkóðun hefst.

| Færibreyta | Regla |
| --- | --- |
| `inspectionSystemId` | Áskilið SystemId GUID opinnar skoðunar sem er ekki tómt |
| `base64` | Myndbæti sem base64-texti sem er ekki tómur; útilokar `stagingId` |
| `stagingId` | GUID eigin sviðsettrar upphleðslu sem er ekki tómt; útilokar `base64` |
| `fileName` | Valfrjálst heiti, 1–250 stafir án slóðaskilja; sjálfgefið `inspection-picture` |
| `expectedCount` | Valfrjáls heiltala; verður að vera 1 (ein skoðun) |

Viðskeyti myndsniðs sem greint er úr bætunum er bætt við heitið; grunnheitið er stytt svo vistað heiti rúmist í 250 stöfum. Óþekktum lyklum er hafnað.

```json
{
  "status": "Success",
  "inspectionSystemId": "<SystemId-skoðunar>",
  "additionalHandlingApplied": false
}
```

Skráning skiptir út myndreitnum og varðveitir ekki fyrri myndir. Engin myndavél er notuð,
skráargluggi opnaður, viðbótarviðhengi búið til eða mynd send í OneDrive.
Viðbótarferli Microsoft fyrir myndir er staðbundið/innra og því ekki tiltækt í opinbera
viðmótinu. `additionalHandlingApplied` er alltaf `false`.

| Höfnun | Dæmi |
| --- | --- |
| `MissingParameter` | Auðkenni skoðunar eða bæði myndinntök vantar |
| `InvalidParameter` | Ógilt GUID, bæði inntök, gölluð bæti, óleyfilegt myndsnið, yfir 1 MiB eða ógilt skráarheiti |
| `UnknownParameter` | Óskilgreindur lykill |
| `PreconditionFailed` | Lokin skoðun eða `expectedCount` annað en heiltalan 1 |
| `RecordNotFound` | Óþekkt skoðun eða sviðssett upphleðsla ekki tiltæk |
| `PermissionDenied` | Full-heimild eða staðlaða breytingaheimild á skoðun vantar |
| `BusinessCentralError` | Staðlað mynd- eða gagnagrunnsskrif mistókst |

Týpaðar hafnanir innihalda `parameter`, `expected` og `nextStep`. Óþekkt auðkenni sviðsetningar,
auðkenni annarra notenda og auðkenni annarra fyrirtækja fá sömu höfnun án upplýsingaleka.
`BIFROST QM Full ori` veitir aðgerðarheimildina. Les- og grunnhlutverk geta ekki skrifað;
staðlaðar breytingaheimildir á skoðun eru einnig nauðsynlegar.

1. Sviðsettu mynd í Foundation eða kóðaðu litla mynd sem base64.
2. Lestu SystemId opinnar skoðunar.
3. Sendu beiðnina. Við árangur er sviðsetning fjarlægð. Við sérhverja höfnun eða bilun er hún
   varðveitt og fyrri mynd skoðunar helst óbreytt.

Opinbera `Blob Staging ori.Take` og myndskrif keyra í sömu færslu. Staðfesting eftir Take veldur
villu við höfnun svo eyðing sviðsetningar bakfærist. Beinar staðfestingar frá áskrifendum eru
bannaðar. Í ham án staðfestingar ber kallandi ábyrgð á staðfestingu og bakfærslu og má ekki grípa
villu án bakfærslu. Endurtekið base64-kall skiptir út mynd með nýju myndauðkenni og er ekki
ídempotent; sviðssett upphleðsla getur aðeins tekist einu sinni. Engin ytri þjónusta er kölluð.

Þjónustulýsing og höfnun fylgja tungumáli kallanda. Foundation skilar opinberum samningsköflum
á ensku að hönnun, einnig fyrir LCID 1039. Forritið á enskar og íslenskar samningsmerkingar og
leiðbeiningar; engin hjálparsía eða breyting á contextSensitiveHelpUrl er nauðsynleg.
