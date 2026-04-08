# Data Sources

## United States Military Expenditure

**Source:** SIPRI Military Expenditure Database, accessed via Our World in Data.

**URL (programmatic):**
```
https://ourworldindata.org/grapher/military-spending-sipri.csv?v=1&csvType=filtered&useColumnShortNames=true&tab=chart&country=USA
```

**Original database:** Stockholm International Peace Research Institute (SIPRI), Military Expenditure Database. https://sipri.org/databases/milex

**Coverage used:** 1960–1990 (database spans 1949–2024).

**Units:** Constant 2023 USD.

**License:** SIPRI data is freely available for non-commercial academic and research use with attribution.

**Citation:**
Stockholm International Peace Research Institute (2024). SIPRI Military Expenditure Database. Retrieved via Our World in Data, https://ourworldindata.org/military-spending.

---

## Soviet Union Military Expenditure

**Source:** CIA declassified estimates, as compiled in:

Haines, G. K., & Leggett, R. E. (Eds.) (2013). *Analyzing Soviet Defense Programs, 1951–1990*. NSA Electronic Briefing Book No. 431. National Security Archive, George Washington University.
https://nsarchive2.gwu.edu/NSAEBB/NSAEBB431/

**Why this source:**
SIPRI explicitly states it cannot produce reliable Soviet military expenditure figures before 1988, due to severe difficulties in obtaining and validating data from the USSR. The World Bank similarly lacks pre-1988 coverage. The CIA's internal estimates, produced over decades by the Office of Strategic Research and declassified after the Cold War, are the only systematic open-source series available for this period.

**Units:** Originally in constant 1982 rubles. Converted to approximate constant USD using the Maddison Project Database (2010) GDP deflator and purchasing power parity estimates for the USSR. Both series are subsequently normalized to 1960 = 1.0 before fitting, so the unit conversion affects only the interpretation of absolute magnitudes, not the Richardson parameter estimates.

**Maddison reference:**
Maddison, A. (2010). *Maddison Project Database*. University of Groningen. https://www.rug.nl/ggdc/historicaldevelopment/maddison/

**License:** CIA documents declassified under Freedom of Information Act requests are in the public domain.

---

## Notes on Data Uncertainty

The Soviet figures carry substantially more uncertainty than the US figures. This is acknowledged in the fitting procedure: USSR residuals are weighted 1.5× relative to US residuals in the `lsqnonlin` objective function. This prevents the optimizer from sacrificing the quality of the Soviet fit to achieve a marginally better US fit.

Users should treat the fitted Soviet-side parameters (`b`, `n`, `s`) as order-of-magnitude estimates rather than precise quantities.
