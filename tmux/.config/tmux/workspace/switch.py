"""Pick another session by number or fuzzy name."""

from collections.abc import Sequence
from typing import NamedTuple

import persist
import tmux
import ui

_SLOT_OPTION = "@slot"
_MAX_BOUND_DIGIT = 9
# Key order is precedence: a session with both flags shows "ask".
_FLAG_MARKERS = {"ask": "?", "done": "✓"}
_LABEL_WIDTH = 20


class SlottedSession(NamedTuple):
    slot: int
    name: str
    ticket_slug: str
    claude_flag: str


def assign_slots(sessions: Sequence[tmux.SessionInfo]) -> dict[str, int]:
    """Existing slots kept as-is; unslotted sessions get the lowest free slot, oldest first."""
    taken = {record.slot for record in sessions if record.slot is not None}
    slots = {record.name: record.slot for record in sessions if record.slot is not None}
    unslotted = sorted(
        (record for record in sessions if record.slot is None),
        key=lambda record: record.created,
    )
    candidate = 1
    for record in unslotted:
        while candidate in taken:
            candidate += 1
        taken.add(candidate)
        slots[record.name] = candidate
    return slots


def _claude_flag(windows: Sequence[tmux.SessionWindow]) -> str:
    flags = {window.claude_flag for window in windows}
    return next((flag for flag in _FLAG_MARKERS if flag in flags), "")


def _digit_binds(rows: Sequence[SlottedSession]) -> list[str]:
    # pos() addresses the input list by position, not the slot number, so the
    # gaps between slots have to be mapped away here.
    positions = {row.slot: position for position, row in enumerate(rows, start=1)}
    binds: list[str] = []
    for digit in range(1, _MAX_BOUND_DIGIT + 1):
        position = positions.get(digit)
        if position is None:
            continue
        binds.append(
            f'{digit}:transform:[ -z "$FZF_QUERY" ] && echo "pos({position})+accept"'
            f' || echo "put({digit})"'
        )
    return binds


def _label(row: SlottedSession) -> str:
    slug = row.ticket_slug
    if not slug or slug == row.name:
        return ""
    if len(slug) > _LABEL_WIDTH:
        return f"{slug[: _LABEL_WIDTH - 1]}…"
    return slug


def switch_session() -> None:
    snapshot = tmux.snapshot()
    slots = assign_slots(snapshot.sessions)
    unslotted = [info for info in snapshot.sessions if info.slot is None]
    if unslotted:
        tmux.set_options(
            [
                tmux.SessionOptionUpdate(info.name, _SLOT_OPTION, str(slots[info.name]))
                for info in unslotted
            ]
        )
        persist.save_state()
    rows = sorted(
        (
            SlottedSession(
                slot=slots[info.name],
                name=info.name,
                ticket_slug=info.ticket_slug,
                claude_flag=_claude_flag(snapshot.windows[info.name]),
            )
            for info in snapshot.sessions
        ),
        key=lambda row: row.slot,
    )
    name_width = max(len(row.name) for row in rows)
    lines = [
        (
            f"{row.name}\t{row.slot:>2}  {row.name:<{name_width}}"
            f" {'*' if row.name == snapshot.current else ' '}"
            f"{_FLAG_MARKERS.get(row.claude_flag, ' ')}"
            f"  {_label(row)}"
        ).rstrip()
        for row in rows
    ]
    choice = ui.pick(lines, "Switch ❯ ", binds=_digit_binds(rows), delimiter="\t")
    if choice is None:
        return
    name = choice.split("\t", 1)[0]
    tmux.focus_session(name)
