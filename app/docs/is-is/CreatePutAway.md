# Quality.Disposition.CreatePutAway

```json
{
  "type": "Quality.Disposition.CreatePutAway",
  "data": {
    "inspectionSystemId": "00000000-0000-0000-0000-000000000001",
    "kind": "internal",
    "quantityBasis": "failed",
    "confirm": true,
    "expectedCount": 1
  }
}
```

Stofnar innri frágang eða vöruhúsafrágang með stöðluðu ráðstöfunarviðmóti Microsoft. Ekkert er skráð eða bókað.

Ekki ídempótent: endurtekið heppnað kall getur stofnað annað skjal.

Notaðu `kind=internal` eða `kind=warehouse` og `quantityBasis=failed` eða `quantityBasis=passed`. Valfrjálst `quantity` er jákvætt grunnmagn, mest valið magn skoðunar. `sourceLocationCode` (10 stafir) og `sourceBinCode` (20 stafir) eru nákvæmir kóðar án síusetningar. `releaseImmediately` er sjálfgefið false og hafnað fyrir vöruhúsafrágang, jafnvel ef false. Losun innri frágangs skráir ekki birgðir.

`confirm=true` er nauðsynlegt. `expectedCount` telur nákvæmlega eina skoðun, ekki skjöl eða línur. Öðru sendu gildi en 1 er hafnað. Ef sleppt er forskoðað án breytinga þegar krafist er staðfestingar fyrir óafturkræf skilaboð. Svar skilar `documentNumbers`, `kind`, `released` og `registered=false`.

Kallandi þarf BIFROST QM Full ori og innbyggðar vöruhúsaheimildir. Stilla þarf staðsetningar, hólf, númeraraðir og frágangssniðmát og hafa nægar birgðir. Innbyggð höfnun eða sein villa afturkallar öll skjöl. Villur tilgreina `parameter`, `expected` og `nextStep`.
