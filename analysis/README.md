# PMT charge plots

Create a separate histogram for the three charge branches in a simulator ROOT
file (`charge_pmt_0`, `charge_pmt_1`, and `charge_pmt_2`):

```bash
python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/Detector-1.root
```

The script requires the Python bindings distributed with ROOT. It writes the
three `TH1I` histograms to `analysis/output/pmt_charge_histograms.root`, and
also writes `charge_pmt_0.png`, `charge_pmt_1.png`, and `charge_pmt_2.png`
when ROOT's image-rendering libraries are available. Use `--output-dir`,
`--bins`, or `--tree` to adjust the output directory, bin count, or tree name.
