#!/usr/bin/env python3
"""Create one charge histogram for each PMT in a simulator ROOT file.

For every PMT a quadratic (pol2) fit is performed over a configurable charge
window (default 30-150 photoelectrons). The vertex of the parabola,
x_peak = -p1 / (2*p2), is reported as an estimate of the peak charge (useful
to locate the muon/VEM hump in a water-Cherenkov charge spectrum).

Example:
    python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/Detector-1.root
    python3 analysis/plot_pmt_charges.py Detector-1.root --fit-min 30 --fit-max 150
"""

from __future__ import annotations

import argparse
from pathlib import Path

import ROOT


BRANCHES = ("charge_pmt_0", "charge_pmt_1", "charge_pmt_2")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_file", type=Path, help="Input ROOT file")
    parser.add_argument("--tree", default="Detector", help="TTree name (default: Detector)")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("analysis/output"),
        help="Directory for generated histogram files (default: analysis/output)",
    )
    parser.add_argument("--bins", type=int, default=100, help="Histogram bins (default: 100)")
    parser.add_argument(
        "--fit-min",
        type=float,
        default=30.0,
        help="Lower charge bound for the quadratic fit (default: 30)",
    )
    parser.add_argument(
        "--fit-max",
        type=float,
        default=100.0,
        help="Upper charge bound for the quadratic fit (default: 150)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.bins <= 0:
        raise ValueError("--bins must be positive")
    if args.fit_min >= args.fit_max:
        raise ValueError("--fit-min must be smaller than --fit-max")

    root_file = ROOT.TFile.Open(str(args.input_file), "READ")
    if not root_file or root_file.IsZombie():
        raise OSError(f"Cannot open ROOT file: {args.input_file}")

    tree = root_file.Get(args.tree)
    if not tree or not tree.InheritsFrom("TTree"):
        raise KeyError(f"Cannot find TTree '{args.tree}' in {args.input_file}")

    missing = [branch for branch in BRANCHES if not tree.GetBranch(branch)]
    if missing:
        raise KeyError(f"Missing required branch(es): {', '.join(missing)}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    ROOT.gROOT.SetBatch(True)
    ROOT.gStyle.SetOptStat(1110)
    ROOT.gStyle.SetOptFit(1111)  # show fit: probability, chi2/ndf and parameters

    histograms = []
    fit_functions = []  # keep references alive so ROOT does not garbage-collect them
    overlays = []       # vertical lines + labels, also kept alive until SaveAs
    for pmt, branch in enumerate(BRANCHES):
        maximum = max(float(tree.GetMaximum(branch)), 1.0)
        upper_edge = maximum * 1.05
        histogram = ROOT.TH1I(
            f"hist_{branch}",
            f"PMT {pmt} charge;Charge [photoelectrons];Entries",
            args.bins,
            0.0,
            upper_edge,
        )
        tree.Draw(f"{branch}>>{histogram.GetName()}", "", "goff")
        histogram.SetDirectory(0)
        histograms.append(histogram)

        # --- Quadratic (pol2) fit over [fit_min, fit_max] ---
        quad = ROOT.TF1(f"quad_pmt_{pmt}", "pol2", args.fit_min, args.fit_max)
        quad.SetLineColor(ROOT.kRed)
        quad.SetLineWidth(2)
        # "R": restrict to the TF1 range; "S": return TFitResultPtr; "Q": quiet
        fit_result = histogram.Fit(quad, "RSQ")
        fit_functions.append(quad)

        # Parabola vertex -> estimate of the peak (or minimum) charge.
        p0, p1, p2 = (quad.GetParameter(i) for i in range(3))
        ndf = quad.GetNDF()
        chi2_ndf = quad.GetChisquare() / ndf if ndf > 0 else float("nan")
        if p2 != 0.0:
            x_peak = -p1 / (2.0 * p2)
            y_peak = quad.Eval(x_peak)
            is_max = p2 < 0
            shape = "maximum" if is_max else "minimum"
            print(
                f"PMT {pmt}: pol2 fit [{args.fit_min:g}, {args.fit_max:g}] "
                f"chi2/ndf = {chi2_ndf:.3f} | "
                f"{shape} at charge = {x_peak:.2f} PE (Entries = {y_peak:.1f})"
            )
        else:
            x_peak, is_max = None, False
            print(
                f"PMT {pmt}: pol2 fit [{args.fit_min:g}, {args.fit_max:g}] "
                f"chi2/ndf = {chi2_ndf:.3f} | curvature p2 = 0 (linear fit)"
            )

        canvas = ROOT.TCanvas(f"canvas_pmt_{pmt}", f"PMT {pmt}", 900, 700)
        canvas.SetLogy()
        canvas.SetGridx()
        canvas.SetGridy()

        histogram.GetXaxis().SetRangeUser(0.0, 400.0)
        histogram.Draw("HIST")
        quad.Draw("SAME")  # overlay the fitted parabola on the histogram

        # --- vertical line at the parabola vertex ("máx @ N PE") ---
        if x_peak is not None:
            canvas.Update()  # needed so gPad y-range is computed (log scale)
            ymin = 10.0 ** ROOT.gPad.GetUymin()  # log pad -> linear user coord
            ymax = 10.0 ** ROOT.gPad.GetUymax()
            vline = ROOT.TLine(x_peak, ymin, x_peak, ymax)
            vline.SetLineColor(ROOT.kRed)
            vline.SetLineStyle(2)  # dashed
            vline.SetLineWidth(1)
            vline.Draw("SAME")

            label = ROOT.TLatex()
            label.SetNDC(True)
            label.SetTextColor(ROOT.kRed)
            label.SetTextSize(0.032)
            label.SetTextAlign(13)  # left-top
            tag = "máx" if is_max else "mín"
            label.DrawLatex(0.62, 0.60, f"{tag} @ {x_peak:.1f} PE")
            overlays.extend([vline, label])  # keep references alive

        output = args.output_dir / f"charge_pmt_{pmt}.png"
        canvas.SaveAs(str(output))
        if output.is_file():
            print(f"Wrote {output}")
        else:
            print(f"Could not render {output}; the histograms are still saved in the ROOT output file.")

    root_file.Close()
    histogram_file = ROOT.TFile(str(args.output_dir / "pmt_charge_histograms.root"), "RECREATE")
    for histogram in histograms:
        histogram.Write()  # the associated pol2 fit is stored together with the histogram
    histogram_file.Close()
    print(f"Wrote {args.output_dir / 'pmt_charge_histograms.root'}")


if __name__ == "__main__":
    main()
