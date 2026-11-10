# Quality.Inspection.CreateReinspection

Stofnar endurskoðun með stöðluðu aðferðinni `Qlty. Inspection Header.CreateReinspection(var header)` og kótaeiningunni `Qlty. Inspection - Create`. Krefst `BIFROST QM Full ori` og staðlaðra gagnaheimilda gæðaskoðunarmanns. Fullt Foundation-hlutverk veitir Bifröst-aðgerðarheimildina; leshlutverk heimilar ekki aðgerðina.

```json
{"type":"Quality.Inspection.CreateReinspection","data":{"inspectionSystemId":"<SystemId-upprunalegrar-skoðunar>"}}
```

`inspectionSystemId` er eina leyfða gagnaviðfangið: GUID sem er ekki tómt og auðkennir sýnilega skoðun. Vantar auðkenni, rangt GUID, óþekkt færsla eða óþekktir lyklar leiða til höfnunar með villukóða án gagnabreytinga. Svar inniheldur `systemId`, `inspectionNo`, `reinspectionNo` og `sourceSystemId`.

Opin upprunaskoðun er fyrst kláruð með stöðluðum athugunum. Ný útgáfa er byggð á nýjustu skoðun með sama númeri, jafnvel þótt eldra SystemId sé sent. Ný skoðun er opin, niðurstöður og lokaupplýsingar eru hreinsaðar, línur eru myndaðar úr sniðmáti og fyrri útgáfa missir merkingu nýjustu endurskoðunar. Staðlaðar athuganir á uppsetningu, niðurstöðu, vörurakningu og heimildum gilda.

**Ekki ídempotent:** hver keyrsla sem tekst stofnar aðra útgáfu. Lestu fyrra svar áður en þú reynir aftur. Staðlaða töfluaðferðin staðfestir ekki færslu með Commit; síðara Commit síðuaðgerðar er ekki keyrt. Sérstök Commit í áskrifendum eru höfnuð. Venjuleg keyrsla staðfestir breytingar eftir árangur; villa afturkallar allar breytingar staðlaðrar aðgerðar. Í ham án staðfestingar berst villa til umlykjandi færslu til afturköllunar. Engar ytri þjónustur eru kallaðar.

Hjálparsamningur er einnig aðgengilegur með `Help.Implementation.Get` eða `get_message_type_help`.

Ef notandi hættir við staðfestingu er aðgerðinni hafnað og fyrri lokun upprunalegrar skoðunar afturkölluð.
