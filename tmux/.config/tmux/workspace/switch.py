"""Pick another session by number or fuzzy name."""

from __future__ import annotations

from collections.abc import Sequence
from typing import NamedTuple

import persist
import tmux
import ui

_SLOT_OPTION = "@slot"
_MAX_BOUND_DIGIT = 9
_FLAG_MARKERS = {"ask": " ?", "done": " ✓"}


class SessionRecord(NamedTuple):
    name: str
    created: int
    slot: int | None


class SlottedSession(NamedTuple):
    slot: int
    name: str


def assign_slots(sessions: Sequence[SessionRecord]) -> dict[str, int]:
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


def _current_records() -> list[SessionRecord]:
    records: list[SessionRecord] = []
    for session in tmux.list_sessions():
        raw_slot = tmux.session_option(session.name, _SLOT_OPTION)
        records.append(
            SessionRecord(
                name=session.name,
                created=session.created,
                slot=int(raw_slot) if raw_slot else None,
            )
        )
    return records


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


def switch_session() -> None:
    current = tmux.current_session()
    records = _current_records()
    slots = assign_slots(records)
    unslotted = [record for record in records if record.slot is None]
    for record in unslotted:
        tmux.set_session_option(record.name, _SLOT_OPTION, str(slots[record.name]))
    if unslotted:
        persist.save_state()
    rows = sorted(
        (
            SlottedSession(slot=slots[record.name], name=record.name)
            for record in records
        ),
        key=lambda row: row.slot,
    )
    flags = tmux.flagged_sessions()
    lines = [
        f"{row.name}\t{row.slot:>2}  {row.name}"
        f"{_FLAG_MARKERS.get(flags.get(row.name), '')}"
        f"{' *' if row.name == current else ''}"
        for row in rows
    ]
    choice = ui.pick(lines, "Switch ❯ ", binds=_digit_binds(rows), delimiter="\t")
    if choice is None:
        return
    name = choice.split("\t", 1)[0]
    tmux.focus_session(name)
