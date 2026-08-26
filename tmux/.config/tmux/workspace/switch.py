"""Pick another session by number or fuzzy name."""

from __future__ import annotations

import json
import os
from collections.abc import Sequence
from pathlib import Path
from typing import NamedTuple

import tmux
import ui

_SLOT_OPTION = "@slot"
_MAX_BOUND_DIGIT = 9
_STATE_PATH = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    / "tmux-workspace"
    / "slots.json"
)


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


def save_slots() -> None:
    """Mirror live slots to disk: session options die with the server."""
    slots = {
        record.name: record.slot
        for record in _current_records()
        if record.slot is not None
    }
    _STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    _STATE_PATH.write_text(json.dumps(slots))


def restore_slots() -> None:
    """Reapply saved slots by session name, leaving live slots untouched."""
    try:
        saved: dict[str, int] = json.loads(_STATE_PATH.read_text())
    except FileNotFoundError:
        return
    records = _current_records()
    taken = {record.slot for record in records if record.slot is not None}
    for record in records:
        slot = saved.get(record.name)
        if record.slot is None and slot is not None and slot not in taken:
            taken.add(slot)
            tmux.set_session_option(record.name, _SLOT_OPTION, str(slot))


def switch_session() -> None:
    current = tmux.current_session()
    records = _current_records()
    slots = assign_slots(records)
    for record in records:
        if record.slot is None:
            tmux.set_session_option(record.name, _SLOT_OPTION, str(slots[record.name]))
    rows = sorted(
        (
            SlottedSession(slot=slots[record.name], name=record.name)
            for record in records
        ),
        key=lambda row: row.slot,
    )
    lines = [
        f"{row.slot:>2}  {row.name}{' *' if row.name == current else ''}"
        for row in rows
    ]
    choice = ui.pick(lines, "Switch ❯ ", binds=_digit_binds(rows))
    if choice is None:
        return
    name = choice.split("  ", 1)[1].removesuffix(" *")
    tmux.focus_session(name)
