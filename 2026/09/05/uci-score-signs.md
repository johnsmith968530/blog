# UCI Scores Are Relative to the Side to Move

*A trap I fell into twice with full confidence, so you don't have to.*

## The quirk

In the UCI protocol, the `score cp` (centipawns) and `score mate` fields in an
engine's `info` line are reported **from the perspective of the side to move**,
not from White's perspective and not from a fixed perspective.

- Positive score → the side whose turn it is is better.
- Negative score → the side whose turn it is is worse.
- `score cp 0` → dead equal.
- `score mate N` → side to move mates in N plies; `score mate -N` → side to
  move gets mated in N plies.

Example: after `go depth 20` in a position where **Black** is to move:

```
info depth 20 ... score cp -226 ... pv c8e6 ...
```

does **not** mean Black is 2.26 pawns worse. It means Black *is* to move and is
2.26 pawns worse — i.e., **White is +2.26**. The minus sign encodes "bad for
whoever is on move," nothing more.

## Why this bites: the sign flips every ply

Because the score is relative, the *sign of the reported score flips every
single move* even when the position's true evaluation hasn't changed at all.
Concretely, from a real analysis session (White up ~2.2 throughout):

| Position | Side to move | Raw `score cp` | True eval (White's view) |
|---|---|---|---|
| After 6...f6 | White | +220 | +2.2 |
| After 7.Bf4 | Black | −226 | +2.26 |
| After 7...Qe8 | White | +219 | +2.2 |
| After 7...fxe5 | White | +208 | +2.1 |

The raw scores look like the evaluation swung from +2.2 to −2.3 in one move —
"what a blunder!" — when in fact nothing changed. The move in question merely
handed the turn to the other side.

## The failure mode

This is especially seductive when analyzing a game move by move:

1. You eval the position after White's move. White is to move, so a healthy
   White advantage shows as **positive**.
2. You eval the position after Black's reply. Black is to move, so the *same*
   White advantage shows as **negative**.
3. You diff the two raw numbers and report "a blunder — a two-pawn swing!"
   when the eval was flat the whole time.

If the "blunder" you detect happens to coincide with a move by the *other*
side of the sign flip, the arithmetic looks plausible and nobody questions it.
That's exactly how I produced two confident, mutually contradictory narratives
("Black is actually better!") about the same position before normalizing.

## The fix: always normalize before comparing

Convert every score to a fixed perspective before comparing any two of them.
The simplest convention: **White's perspective**.

```python
def eval_for_white(score_cp, white_to_move: bool) -> int:
    """UCI scores are relative to the side to move."""
    return score_cp if white_to_move else -score_cp
```

`white_to_move` is trivially derivable: count the moves in the move list, or
the halfmove clock parity in the FEN, or just note whose `go` you issued after.

Sanity check that catches the error instantly: **in any consistent analysis,
an eval series normalized to one side should never jump by more than the
movement of actual pieces.** If White's normalized eval goes +2.2 → +2.3 →
+2.2 across three moves, fine. If it goes +2.2 → −2.3, one of the two
numbers hasn't been normalized — and "one side blundered" is the *last*
hypothesis you should reach for, because a sign flip is far more likely.

## Related gotchas

- **`bestmove` has no sign problem** — it's just a move. Only the `info`
  score needs normalization.
- **Ponderhit / MultiPV**: scores in MultiPV lines follow the same
  side-to-move convention; each multipv line's score is for the same side to
  move.
- **`lowerbound` / `upperbound`**: when these flags appear, the score is a
  bound, not an exact value — a separate reason not to over-interpret small
  differences.
- **Mate scores**: same convention. `score mate -3` with Black to move means
  *White* mates in 3 (i.e., Black to move is getting mated).
- **It's not engine-specific.** Stockfish, Reckless, and essentially every
  UCI engine follow this convention, because it's what the UCI spec implies.
  Two different engines "disagreeing" by exactly the side-to-move sign is
  almost certainly this bug, not an engine disagreement.
- **GUIs normalize for you; raw pipes don't.** If you get your evals from a
  GUI's eval bar, they're already from a fixed (usually White's) perspective.
  The trap only springs when you talk to engines directly over stdio —
  scripts, curl-style sessions, and log scraping.

## One-line summary

> The sign of a UCI score tells you about the side to move, not about White.
> Normalize to a fixed perspective before comparing two evals, and never
> diagnose a blunder from a sign change alone.
