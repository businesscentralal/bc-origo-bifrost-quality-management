---
title: Quality.Inspection.Reopen
audience: developer, admin
keywords: gæði, skoðun, enduropna
locale: is-is
---

```json
{"type":"Quality.Inspection.Reopen","data":{"inspectionSystemId":"00000000-0000-0000-0000-000000000001"}}
```

Enduropnar eina lokna skoðun með því að kalla á `Qlty. Inspection Header.ReopenInspection` frá Microsoft. Skilaboðin skrifa hvorki stöðu né magn sjálf.

| Nauðsynlegur lykill | Gildi |
| --- | --- |
| `inspectionSystemId` | SystemId skoðunarinnar og endurskoðunarinnar sem á að enduropna |

Lykli sem vantar, lykli sem er ekki GUID, óþekktum lykli eða skoðun sem er ekki til er hafnað áður en skrifað er. Microsoft hafnar aðgerðinni þegar notandi er hvorki Quality Admin & Supervisor né SUPER, eða þegar síðari endurskoðun er til. Sú höfnun er `status: Error` og skilur skoðunina óbreytta.

Áhrif: lokin skoðun verður opin. Í þessari útgáfu af Business Central vistar `ReopenInspection` færsluna á eftir, og magn sem stóðst og féll helst. Aðgerðin er ídempotent: annað kall á opna skoðun breytir engu. Ekkert `Commit` er á staðlaðri leið. Viðskiptahöfnun bakfærir. Með `Omit Commit` ber kallandi ábyrgð á bakfærslu.

Úthlutaðu `BIFROST QM Full ori` með vinnsluhlutverki Foundation. Les- og grunnsöfnin geta ekki keyrt þessa aðgerð. Microsoft athugar enn að Quality Admin & Supervisor, eða SUPER, sé úthlutað á notandann. Engin ytri þjónusta er kölluð.

Notaðu `Data.Records.Get` í Foundation fyrir venjulegan lestur. Beint `Data.Records.Set` á stöðu er ekki þessi aðgerð.
