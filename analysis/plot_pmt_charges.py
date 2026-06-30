#!/usr/bin/env python3
"""Create PMT charge histograms for the main particle groups in a simulator ROOT file.

The analysis builds four groups in one pass over the ROOT tree:
    - electromagnetic: e-, e+, gamma
    - muons: mu-, mu+
    - neutrons: neutron, anti-neutron
    - all particles

For each PMT it writes one overlay canvas with all four groups and one single-group
canvas for each group. All histograms are also saved in one ROOT file.

Example:
    python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/tanca_test.root
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import ROOT


BRANCHES = ("charge_pmt_0", "charge_pmt_1", "charge_pmt_2")
PARTICLE_BRANCHES = ("partId", "part_id", "pdg", "PDG", "particle_id")
PARTICLE_LABELS = {
    22: "gamma",
    11: "e-", -11: "e+",
    13: "mu-", -13: "mu+",
    2112: "neutron", -2112: "anti-neutron",
    2212: "proton", -2212: "anti-proton",
    211: "pi+", -211: "pi-",
}


@dataclass(frozen=True)
class ParticleGroup:
    key: str
    label: str
    pdg_ids: frozenset[int] | None
    color: int


GROUPS = (
    ParticleGroup("electromagnetic", "e^{#pm} + #gamma", frozenset({11, -11, 22}), ROOT.kBlue + 1),
    ParticleGroup("muons", "#mu^{#pm}", frozenset({13, -13}), ROOT.kRed + 1),
    ParticleGroup("neutrons", "n", frozenset({2112, -2112}), ROOT.kGreen + 2),
    ParticleGroup("all", "all particles", None, ROOT.kBlack),
)


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
        "--x-max",
        type=float,
        default=600.0,
        help="Histogram x-axis maximum in photoelectrons (default: 600).",
    )
    parser.add_argument(
        "--no-png",
        action="store_true",
        help="Do not render PNG canvases; still write the ROOT histogram file.",
    )
    return parser.parse_args()


def particle_branch_name(tree: ROOT.TTree) -> str:
    branch = next((name for name in PARTICLE_BRANCHES if tree.GetBranch(name)), None)
    if branch is None:
        raise KeyError(f"No particle-id branch found. Tried: {', '.join(PARTICLE_BRANCHES)}")
    return branch


def configure_tree_branches(tree: ROOT.TTree, particle_branch: str) -> None:
    tree.SetBranchStatus("*", 0)
    tree.SetBranchStatus(particle_branch, 1)
    for branch in BRANCHES:
        tree.SetBranchStatus(branch, 1)


def print_particle_counts(counts: dict[int, int]) -> None:
    if not counts:
        return
    total = sum(counts.values())
    print("Particle composition:")
    for pid, count in sorted(counts.items(), key=lambda item: item[1], reverse=True):
        label = PARTICLE_LABELS.get(pid, str(pid))
        print(f"  {label:>12s} ({pid:>11d}): {count:>8d} entries ({100.0 * count / total:6.2f}%)")


def make_histograms(args: argparse.Namespace) -> dict[str, list[ROOT.TH1I]]:
    histograms: dict[str, list[ROOT.TH1I]] = {}
    for group in GROUPS:
        group_histograms = []
        for pmt, branch in enumerate(BRANCHES):
            histogram = ROOT.TH1I(
                f"hist_{branch}_{group.key}",
                f"PMT {pmt} charge ({group.label});Charge [photoelectrons];Entries",
                args.bins,
                0.0,
                args.x_max,
            )
            histogram.SetDirectory(0)
            histogram.SetLineColor(group.color)
            histogram.SetMarkerColor(group.color)
            histogram.SetLineWidth(2)
            group_histograms.append(histogram)
        histograms[group.key] = group_histograms
    return histograms


def fill_histograms(
    tree: ROOT.TTree,
    particle_branch: str,
    histograms: dict[str, list[ROOT.TH1I]],
) -> tuple[dict[str, int], dict[int, int]]:
    group_counts = {group.key: 0 for group in GROUPS}
    particle_counts: dict[int, int] = {}

    for event in tree:
        particle_id = int(getattr(event, particle_branch))
        particle_counts[particle_id] = particle_counts.get(particle_id, 0) + 1
        charges = (float(event.charge_pmt_0), float(event.charge_pmt_1), float(event.charge_pmt_2))

        for group in GROUPS:
            if group.pdg_ids is not None and particle_id not in group.pdg_ids:
                continue
            for pmt, charge in enumerate(charges):
                ROOT.TH1.Fill(histograms[group.key][pmt], charge)
            group_counts[group.key] += 1

    return group_counts, particle_counts


def draw_single_histogram(histogram: ROOT.TH1I, output: Path, x_max: float) -> None:
    canvas = ROOT.TCanvas(f"canvas_{histogram.GetName()}", histogram.GetTitle(), 900, 700)
    canvas.SetLogy()
    histogram.GetXaxis().SetRangeUser(0.0, x_max)
    histogram.Draw("HIST")
    canvas.SaveAs(str(output))
    if output.is_file():
        print(f"Wrote {output}")
    else:
        print(f"Could not render {output}; histogram is still saved in the ROOT output file.")


def draw_overlay(pmt: int, histograms: dict[str, list[ROOT.TH1I]], output: Path, x_max: float) -> None:
    canvas = ROOT.TCanvas(f"canvas_pmt_{pmt}_groups", f"PMT {pmt} charge by particle group", 900, 700)
    canvas.SetLogy()
    legend = ROOT.TLegend(0.62, 0.68, 0.88, 0.88)
    legend.SetBorderSize(0)
    legend.SetFillStyle(0)

    first = True
    for group in GROUPS:
        histogram = histograms[group.key][pmt]
        histogram.GetXaxis().SetRangeUser(0.0, x_max)
        histogram.SetTitle(f"PMT {pmt} charge by particle group;Charge [photoelectrons];Entries")
        histogram.Draw("HIST" if first else "HIST SAME")
        legend.AddEntry(histogram, group.label, "l")
        first = False
    legend.Draw()
    canvas.SaveAs(str(output))
    if output.is_file():
        print(f"Wrote {output}")
    else:
        print(f"Could not render {output}; histograms are still saved in the ROOT output file.")


def write_pngs(histograms: dict[str, list[ROOT.TH1I]], args: argparse.Namespace) -> None:
    for pmt in range(len(BRANCHES)):
        draw_overlay(pmt, histograms, args.output_dir / f"charge_pmt_{pmt}_groups.png", args.x_max)

    for group in GROUPS:
        for pmt, histogram in enumerate(histograms[group.key]):
            draw_single_histogram(
                histogram,
                args.output_dir / f"charge_pmt_{pmt}_{group.key}.png",
                args.x_max,
            )


def write_root_histograms(histograms: dict[str, list[ROOT.TH1I]], args: argparse.Namespace) -> None:
    output = args.output_dir / "pmt_charge_histograms.root"
    histogram_file = ROOT.TFile(str(output), "RECREATE")
    if not histogram_file or histogram_file.IsZombie():
        raise OSError(f"Cannot create ROOT histogram file: {output}")
    histogram_file.cd()
    for group in GROUPS:
        for histogram in histograms[group.key]:
            if histogram.Write() <= 0:
                raise OSError(f"Failed to write histogram {histogram.GetName()} to {output}")
    histogram_file.Close()
    print(f"Wrote {output}")


def main() -> None:
    args = parse_args()
    if args.bins <= 0:
        raise ValueError("--bins must be positive")
    if args.x_max <= 0:
        raise ValueError("--x-max must be positive")

    root_file = ROOT.TFile.Open(str(args.input_file), "READ")
    if not root_file or root_file.IsZombie():
        raise OSError(f"Cannot open ROOT file: {args.input_file}")

    tree = root_file.Get(args.tree)
    if not tree or not tree.InheritsFrom("TTree"):
        raise KeyError(f"Cannot find TTree '{args.tree}' in {args.input_file}")

    missing = [branch for branch in BRANCHES if not tree.GetBranch(branch)]
    if missing:
        raise KeyError(f"Missing required branch(es): {', '.join(missing)}")

    particle_branch = particle_branch_name(tree)
    configure_tree_branches(tree, particle_branch)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    ROOT.gROOT.SetBatch(True)
    ROOT.gStyle.SetOptStat(1110)

    histograms = make_histograms(args)
    group_counts, particle_counts = fill_histograms(tree, particle_branch, histograms)

    print(f"Read {sum(particle_counts.values())} entries")
    print_particle_counts(particle_counts)
    print("Group counts:")
    for group in GROUPS:
        print(f"  {group.label:>14s}: {group_counts[group.key]} entries")

    if not args.no_png:
        write_pngs(histograms, args)
    root_file.Close()
    write_root_histograms(histograms, args)


if __name__ == "__main__":
    main()
